# encoding: utf-8

# File:	include/udba/dialogs.ycp
# Package:	Universal Driver Build Assistant
# Summary:	Dialogs definitions
# Authors:	Boris Manojlovic <boris@steki.net>
#
# $Id: dialogs.ycp $
module Yast
  module UdbaDialogsInclude
    def initialize_udba_dialogs(include_target)
      Yast.import "Pkg"
      Yast.import "UI"

      textdomain "udba"

      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "Udba"
      Yast.import "Package"
      Yast.import "Popup"
      Yast.import "SourceManager"

      Yast.include include_target, "udba/helps.rb"
      Yast.include include_target, "udba/complex.rb"
      Yast.include include_target, "packager/repositories_include.rb"
    end

    # recipeSelectionDialog dialog
    # @return dialog result
    def recipeSelectionDialog
      # Udba configure1 dialog caption
      caption = _("Build Process status")

      # Udba configure1 dialog contents
      contents = VBox(
        LogView(
          Id(:log),
          "Buil&d Output",
          10, # visible lines
          0
        ), # lines to store
        PushButton(Id(:abortbuild), Opt(:default), "&Cancel Build")
      )

      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "c1", ""),
        Label.BackButton,
        Label.NextButton
      )

      # assume it does not exist for some strange reason...
      SCR.Execute(path(".target.bash"), "mkdir -p /var/tmp/udba-build-root/")

      # get file name of recipe tar archive
      output = Convert.to_map(
        SCR.Execute(
          path(".target.bash_output"),
          Builtins.sformat("/bin/rpm -ql %1", Udba.current_working_package)
        )
      )
      Builtins.y2milestone(">>RECIPE>> %1", Udba.current_working_package)
      recipe_archive = ""
      Builtins.foreach(
        Builtins.splitstring(Ops.get_string(output, "stdout", ""), "\n")
      ) do |line2|
        if Builtins.regexpmatch(line2, ".tar.gz$") == true
          Builtins.y2milestone("Matched: %1", line2)
          recipe_archive = line2
          raise Break
        end
      end
      SCR.Execute(
        path(".target.bash"),
        Builtins.sformat(
          "/bin/tar -C /var/tmp/udba-build-root/ -zvxf %1",
          recipe_archive
        )
      )


      # start subprocess
      id = Convert.to_integer(
        SCR.Execute(
          path(".process.start_shell"),
          Builtins.sformat(
            "/usr/lib/udba/bin/udba-builder %1",
            Udba.current_working_package
          )
        )
      )
      line = ""
      ret = :abort
      while SCR.Read(path(".process.running"), id) == true
        line = Convert.to_string(
          SCR.Read(path(".process.read_line_stderr"), id)
        )
        if line != nil
          Builtins.y2warning("BUILD-E: %1", line)
          UI.ChangeWidget(
            Id(:log),
            :LastLine,
            Builtins.sformat("STDERR:%1\n", line)
          )
        end

        line = Convert.to_string(SCR.Read(path(".process.read_line"), id))
        if line != nil
          Builtins.y2warning("BUILD-O: %1", line)
          UI.ChangeWidget(
            Id(:log),
            :LastLine,
            Builtins.sformat("STDOUT:%1\n", line)
          )
        else
          Builtins.sleep(10) # sleep 10 ms is good enough so it is not hogging system while building :)
          # and fast enough to not slow down build...
        end
        ret = Convert.to_symbol(UI.PollInput)
        Builtins.y2milestone("ret=%1", ret) if ret != nil
        # check if the abort button was pressed
        if ret == :abortbuild
          SCR.Execute(path(".process.kill"), id) # kill the subprocess
          ret = :back
          break
        end
      end
      Builtins.y2milestone("----------- LINE START --------")
      Builtins.y2milestone("STDOUT=%1", line) # it should really be "UDBA: Build Complete" but not too reliable so lets
      # assume set -e is a lot more better in this :)
      Builtins.y2milestone("------------ LINE END ---------")

      retval = Convert.to_integer(SCR.Read(path(".process.status"), id))
      if retval != nil && retval != 0 || ret == :back
        Popup.Warning(
          "Package building has failed or has been aborted,\n please look at /var/log/YaST2/y2log file for clues"
        )
      else
        reponame = Builtins.substring(
          Udba.current_working_package,
          Ops.add(Builtins.search(Udba.current_working_package, "-"), 1)
        )
        newSrcMap = {
          "enabled"     => true,
          "autorefresh" => true,
          "name"        => reponame,
          "alias"       => reponame,
          "base_urls"   => [Builtins.sformat("dir:///srv/repos/%1", reponame)],
          "priority"    => 99
        }

        Builtins.y2milestone(
          "Adding repository  %1",
          Builtins.substring(
            Udba.current_working_package,
            Ops.add(Builtins.search(Udba.current_working_package, "-"), 1)
          )
        )
        newSrcID = Pkg.RepositoryAdd(newSrcMap)
        if newSrcID != nil
          Builtins.y2milestone(
            "Successfully added the \"%1\" repository to the system.",
            Builtins.substring(
              Udba.current_working_package,
              Ops.add(Builtins.search(Udba.current_working_package, "-"), 1)
            )
          )
        else
          Builtins.y2error(
            "Could not add \"%1\".",
            Builtins.substring(
              Udba.current_working_package,
              Ops.add(Builtins.search(Udba.current_working_package, "-"), 1)
            )
          )
        end

        Builtins.y2milestone("Saving all source changes to the system.")
        Popup.AnyMessage(
          _("UDBA Build Done!"),
          Builtins.sformat(
            "Requested recipe is built succesfully\nAdded > %1 < repository to system",
            reponame
          )
        )

        Pkg.SourceSaveAll
        ret = :back
      end
      ret = :back if ret == nil
      deep_copy(ret)
    end

    # Configure2 dialog
    # @return dialog result
    def buildProcessDialog
      # Udba configure2 dialog caption
      caption = _("Udba Configuration")

      # Udba configure2 dialog contents
      contents = Label(_("Second part of configuration of udba"))

      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "c2", ""),
        Label.BackButton,
        Label.NextButton
      )

      ret = nil
      while true
        ret = UI.UserInput

        # abort?
        if ret == :abort || ret == :cancel
          if ReallyAbort()
            break
          else
            next
          end
        elsif ret == :next || ret == :back
          break
        else
          Builtins.y2error("unexpected retcode: %1", ret)
          next
        end
      end

      deep_copy(ret)
    end
  end
end
