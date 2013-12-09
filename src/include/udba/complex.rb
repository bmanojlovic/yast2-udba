# encoding: utf-8

# File:	include/udba/complex.ycp
# Package:	Universal Driver Build Assistant
# Summary:	Dialogs definitions
# Authors:	Boris Manojlovic <boris@steki.net>
#
# $Id: complex.ycp $
module Yast
  module UdbaComplexInclude
    def initialize_udba_complex(include_target)
      Yast.import "Pkg"
      Yast.import "UI"

      textdomain "udba"

      Yast.import "Label"
      Yast.import "Popup"
      Yast.import "Wizard"
      #import "Wizard_hw";
      Yast.import "Confirm"
      Yast.import "Udba"
      Yast.import "Package"

      Yast.include include_target, "udba/helps.rb"
    end

    # Return a modification status
    # @return true if data was modified
    def Modified
      Udba.Modified
    end

    def ReallyAbort
      !Udba.Modified || Popup.ReallyAbort(true)
    end

    def PollAbort
      UI.PollInput == :abort
    end

    # Read settings dialog
    # @return `abort if aborted and `next otherwise
    def ReadDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "read", ""))
      Udba.SetAbortFunction(fun_ref(method(:PollAbort), "boolean ()"))
      return :abort if !Confirm.MustBeRoot
      ret = Udba.Read
      ret ? :next : :abort
    end


    # Write settings dialog
    # @return `abort if aborted and `next otherwise
    def WriteDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "write", ""))
      Udba.SetAbortFunction(fun_ref(method(:PollAbort), "boolean ()"))
      ret = Udba.Write
      ret ? :next : :abort
    end

    # Function updates list of packages
    # @param [Array<Yast::Term>] packageList
    # @param [Yast::Term] vals
    # @return [Array<Yast::Term>]

    def updatePkgList(packageList, vals)
      packageList = deep_copy(packageList)
      vals = deep_copy(vals)
      ver1 = ""
      ver2 = ""
      copyOfpackageList = []

      if Builtins.size(packageList) == 0
        Builtins.y2milestone("LIST EMPTY ADDING")
        copyOfpackageList = Builtins.add(copyOfpackageList, vals)
        return deep_copy(copyOfpackageList)
      end
      copyOfpackageList = deep_copy(packageList)
      exist = false
      idx = 0

      Builtins.foreach(packageList) do |t|
        if Ops.get(t, 1) == Ops.get(vals, 1)
          Builtins.y2milestone(
            "package in list removing...: %1",
            Ops.get(vals, 1)
          )
          ver1 = Ops.get_string(t, 2)
          ver2 = Ops.get_string(vals, 2)
          if Ops.less_than(ver1, ver2)
            Ops.set(vals, 2, Builtins.mergestring([ver1, ver2], " : "))
            Ops.set(vals, 3, "Update Available")
          elsif ver1 == ver2
            Ops.set(vals, 3, "No Update Available")
          end
          copyOfpackageList = Builtins.remove(copyOfpackageList, idx)
          raise Break
        end
        idx = Ops.add(idx, 1)
      end
      copyOfpackageList = Builtins.add(copyOfpackageList, vals)
      deep_copy(copyOfpackageList)
    end



    # Create list of udba-* packages
    # @return [Array<Yast::Term>]

    def PreparePackagesList
      packageList = []
      key = 1
      available = ""
      pkg_version = "0.0"
      Builtins.foreach(Pkg.ResolvableProperties("", :package, "")) do |pkg|
        pkg_name = Ops.get_string(pkg, "name", "")
        if Builtins.regexpmatch(pkg_name, "^udba-") == true
          available = "Not Installed" if Ops.get(pkg, "status") == :available
          packageList = updatePkgList(
            packageList,
            Item(
              Id(key),
              Ops.get(pkg, "name"),
              Ops.get_string(pkg, "version", "Null"),
              available,
              Ops.get(pkg, "summary")
            )
          )
          key = Ops.add(key, 1)
        end
      end
      deep_copy(packageList)
    end
    #  there is no popup from DoRemove package call so lets fake it
    def ShouldRemovePackage(package_name)
      Popup.YesNoHeadline("These packages will be removed:?", package_name)
    end

    # Helper functions for getting package name from table selection
    # @return [String] package name
    def GetPackageName
      row_id = Convert.to_integer(UI.QueryWidget(Id(:table), :CurrentItem))
      Convert.to_string(UI.QueryWidget(:table, Cell(row_id, 0)))
    end

    # Helper functions for getting package status from table selection
    # @return [String] status
    def GetUpdateStatus
      row_id = Convert.to_integer(UI.QueryWidget(Id(:table), :CurrentItem))
      Convert.to_string(UI.QueryWidget(:table, Cell(row_id, 3)))
    end

    #list <map<string,any>> selected_packages = [];
    # Summary dialog
    # @return dialog result
    def SummaryDialog
      caption = _("Universal Driver Build Assistant")

      summary = Udba.Summary

      packageList = PreparePackagesList()

      contents = VBox(
        Left(
          Label(_("Currently configured and build status of driver recipes"))
        ),
        Left(
          VBox(
            MinSize(
              70,
              3,
              # A table header
              Table(
                Id(:table),
                Opt(:notify),
                Header(
                  "Package Name",
                  "Version",
                  "Upgrade Available",
                  "Description"
                ),
                packageList
              )
            ),
            HBox(
              # [Install new recipe] [Build recipe] [Remove recipe]
              # a push button
              PushButton(Id("InstallOrUpdate"), _("Install / Update recipe")),
              # a push button
              PushButton(Id("BuildRecipe"), _("Build / Rebuild recipe")),
              # a push button
              PushButton(Id("RemoveRecipe"), _("Remove recipe"))
            ),
            VSpacing(Opt(:hstretch), 1)
          )
        )
      )

      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "summary", ""),
        Label.BackButton,
        Label.FinishButton
      )

      ret = nil
      while true
        ret = UI.UserInput

        # abort?
        if ret == :abort || ret == :cancel || ret == :back
          if ReallyAbort()
            break
          else
            next
          end
        elsif ret == :table
          next
        # BuildRecipe dialog
        elsif ret == "BuildRecipe"
          Builtins.y2milestone("BuildRecipe is called")
          Udba.current_working_package = GetPackageName()
          ret = :configure
        # RemoveRecipe dialog
        elsif ret == "RemoveRecipe"
          Builtins.y2milestone("RemoveRecipe is called")
          package_name = GetPackageName()
          if ShouldRemovePackage(package_name) == true
            Package.DoRemove([package_name])
            tmplist = PreparePackagesList()
            Popup.ClearFeedback
            UI.ChangeWidget(Id(:table), :Items, tmplist)
          end
          next
        # RemoveRecipe dialog
        elsif ret == "InstallOrUpdate"
          Builtins.y2milestone("InstallOrUpdate is called")
          selected = UI.QueryWidget(Id(:table), :CurrentItem)
          if selected == :other
            ret = :other
          else
            package_name = GetPackageName()
            Builtins.y2milestone(
              "Update for '%1' is '%2'",
              GetPackageName(),
              GetUpdateStatus()
            )
            if Package.InstalledAll([package_name]) == false
              Package.InstallAll([package_name])
              Popup.ShowFeedback(
                _("Updating package information"),
                _("This may take a while")
              )
              # this takes time...
              tmplist = PreparePackagesList()
              Popup.ClearFeedback
              UI.ChangeWidget(Id(:table), :Items, tmplist)
              next
            else
              next
            end
          end
          break
        elsif ret == :next
          break
        else
          Builtins.y2error("unexpected retcode: %1", ret)
          next
        end
        Builtins.y2milestone("Returning ret=%1", ret)
        return deep_copy(ret)
      end

      nil
    end
  end
end
