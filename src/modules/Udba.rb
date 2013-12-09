# encoding: utf-8

# File:	modules/Udba.ycp
# Package:	Universal Driver Build Assistant
# Summary:	Udba settings, input and output functions
# Authors:	Boris Manojlovic <boris@steki.net>
#
# $Id: Udba.ycp 41350 2007-10-10 16:59:00Z dfiser $
#
# Representation of Universal Driver Build Assistant.
# Input and output routines.
require "yast"

module Yast
  class UdbaClass < Module
    def main
      Yast.import "Pkg"
      textdomain "udba"

      Yast.import "Installation"
      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Summary"
      Yast.import "Message"
      Yast.import "Package"
      Yast.import "Popup"


      @current_working_package = ""

      # Data was modified?
      @modified = false


      @proposal_valid = false

      # Write only, used during autoinstallation.
      # Don't run services and SuSEconfig, it's all done at one place.
      @write_only = false

      # Abort function
      # return boolean return true if abort
      @AbortFunction = fun_ref(method(:Modified), "boolean ()")

      # Required packages for operation
      # TODO Check do we really need kernel-source for building or kernel-syms should be sufficient?
      @required_packages = [
        "kernel-source",
        "kernel-syms",
        "update-desktop-files",
        "patch",
        "gcc",
        "grep",
        "rpm-build"
      ]
    end

    # Initializes the package manager
    def InitPkg
      if Pkg.TargetInitialize(Installation.destdir) != true
        Builtins.y2error("Cannot initialize target")
        return false
      end

      if Pkg.TargetLoad != true
        Builtins.y2error("Cannot load target")
        return false
      end

      if Pkg.SourceStartManager(true) != true
        Builtins.y2error("Cannot initialize sources")
        return false
      end

      true
    end


    # Abort function
    # @return [Boolean] return true if abort
    def Abort
      return @AbortFunction.call == true if @AbortFunction != nil
      false
    end

    # Data was modified?
    # @return true if modified
    def Modified
      Builtins.y2debug("modified=%1", @modified)
      @modified
    end

    # Mark as modified, for Autoyast.
    def SetModified(value)
      @modified = true

      nil
    end

    def ProposalValid
      @proposal_valid
    end

    def SetProposalValid(value)
      @proposal_valid = value

      nil
    end

    # @return true if module is marked as "write only" (don't start services etc...)
    def WriteOnly
      @write_only
    end

    # Set write_only flag (for autoinstalation).
    def SetWriteOnly(value)
      @write_only = value

      nil
    end


    def SetAbortFunction(function)
      function = deep_copy(function)
      @AbortFunction = deep_copy(function)

      nil
    end


    # Read all udba settings
    # @return true on success
    def Read
      # Udba read dialog caption
      caption = _("Initializing Universal Driver Build Assistant")

      # TODO FIXME Set the right number of stages
      steps = 4

      sl = 200
      Builtins.sleep(sl)

      # TODO FIXME Names of real stages
      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        steps,
        [
          # Progress stage 1/3
          _("Initialize Package Manager..."),
          # Progress stage 2/3
          _("Check for required packages..."),
          # Progress stage 3/3
          _("Read the previous settings")
        ],
        [
          # Progress step 1/3
          _("Initalizing Package Manager..."),
          # Progress step 2/3
          _("Checking for required packages..."),
          # Progress step 3/3
          _("Reading the previous settings..."),
          # Progress finished
          _("Finished")
        ],
        ""
      )

      # Initialize Package Manager...
      return false if Abort()
      Progress.NextStage
      InitPkg()


      # heck for required packages...
      success = true

      return false if Abort()
      Progress.NextStage
      if Package.InstalledAll(@required_packages) == false
        success = Package.InstallAll(@required_packages)
        if success == false
          # error popup
          Report.Error(
            _(
              "Cannot install required packages\n Universal Build Driver Assistant cannot continue!"
            )
          )
          return false
        end
      end

      # Read the previous settings
      return false if Abort()
      Progress.NextStage
      # Error message
      Report.Error(Message.CannotReadCurrentSettings) if false
      Builtins.sleep(sl)


      return false if Abort()
      @modified = false
      true
    end

    # Write all udba settings
    # @return true on success
    def Write
      # Udba read dialog caption
      caption = _("Saving udba Configuration")

      # TODO FIXME And set the right number of stages
      steps = 1

      sl = 500
      Builtins.sleep(sl)

      # TODO FIXME Names of real stages
      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        steps,
        [
          # Progress stage 1/2
          _("Write the settings"),
          # Progress stage 2/2
          _("Run SuSEconfig")
        ],
        [
          # Progress step 1/2
          _("Writing the settings..."),
          # Progress step 2/2
          _("Running SuSEconfig..."),
          # Progress finished
          _("Finished")
        ],
        ""
      )

      # write settings
      return false if Abort()
      Progress.NextStage
      # Error message
      Report.Error(_("Cannot write settings.")) if false
      Builtins.sleep(sl)

      # run SuSEconfig
      return false if Abort()
      Progress.NextStage
      # Error message
      Report.Error(Message.SuSEConfigFailed) if false
      Builtins.sleep(sl)

      return false if Abort()
      # Progress finished
      Progress.NextStage
      Builtins.sleep(sl)

      return false if Abort()
      true
    end

    # Get all udba settings from the first parameter
    # (For use by autoinstallation.)
    # @param [Hash] settings The YCP structure to be imported.
    # @return [Boolean] True on success
    def Import(settings)
      settings = deep_copy(settings)
      # TODO FIXME: your code here (fill the above mentioned variables)...
      true
    end

    # Dump the udba settings to a single map
    # (For use by autoinstallation.)
    # @return [Hash] Dumped settings (later acceptable by Import ())
    def Export
      # TODO FIXME: your code here (return the above mentioned variables)...
      {}
    end

    # Create a textual summary and a list of unconfigured cards
    # @return summary of the current configuration
    def Summary
      # TODO FIXME: your code here...
      # Configuration summary text for autoyast
      [_("Configuration summary..."), []]
    end

    # Create an overview table with all configured cards
    # @return table items
    def Overview
      # TODO FIXME: your code here...
      []
    end

    # Return packages needed to be installed and removed during
    # Autoinstallation to insure module has all needed software
    # installed.
    # @return [Hash] with 2 lists.
    def AutoPackages
      install_pkgs = deep_copy(@required_packages)
      remove_pkgs = []
      { "install" => install_pkgs, "remove" => remove_pkgs }
    end

    publish :function => :Modified, :type => "boolean ()"
    publish :function => :InitPkg, :type => "boolean ()"
    publish :variable => :current_working_package, :type => "string"
    publish :variable => :required_packages, :type => "list <string>"
    publish :function => :Abort, :type => "boolean ()"
    publish :function => :SetModified, :type => "void (boolean)"
    publish :function => :ProposalValid, :type => "boolean ()"
    publish :function => :SetProposalValid, :type => "void (boolean)"
    publish :function => :WriteOnly, :type => "boolean ()"
    publish :function => :SetWriteOnly, :type => "void (boolean)"
    publish :function => :SetAbortFunction, :type => "void (boolean ())"
    publish :function => :Read, :type => "boolean ()"
    publish :function => :Write, :type => "boolean ()"
    publish :function => :Import, :type => "boolean (map)"
    publish :function => :Export, :type => "map ()"
    publish :function => :Summary, :type => "list ()"
    publish :function => :Overview, :type => "list ()"
    publish :function => :AutoPackages, :type => "map ()"
  end

  Udba = UdbaClass.new
  Udba.main
end
