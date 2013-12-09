# encoding: utf-8

# File:	clients/udba_auto.ycp
# Package:	Universal Driver Build Assistant
# Summary:	Client for autoinstallation
# Authors:	Boris Manojlovic <boris@steki.net>
#
# $Id: udba_auto.ycp $
#
# This is a client for autoinstallation. It takes its arguments,
# goes through the configuration and return the setting.
# Does not do any changes to the configuration.

# @param function to execute
# @param map/list of udba settings
# @return [Hash] edited settings, Summary or boolean on success depending on called function
# @example map mm = $[ "FAIL_DELAY" : "77" ];
# @example map ret = WFM::CallFunction ("udba_auto", [ "Summary", mm ]);
module Yast
  class UdbaAutoClient < Client
    def main
      Yast.import "UI"
      Yast.import "Pkg"

      textdomain "udba"

      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("Udba auto started")

      Yast.import "Udba"
      Yast.include self, "udba/wizards.rb"

      @ret = nil
      @func = ""
      @param = {}

      # Check arguments
      if Ops.greater_than(Builtins.size(WFM.Args), 0) &&
          Ops.is_string?(WFM.Args(0))
        @func = Convert.to_string(WFM.Args(0))
        if Ops.greater_than(Builtins.size(WFM.Args), 1) &&
            Ops.is_map?(WFM.Args(1))
          @param = Convert.to_map(WFM.Args(1))
        end
      end
      Builtins.y2debug("func=%1", @func)
      Builtins.y2debug("param=%1", @param)

      # Create a summary
      if @func == "Summary"
        @ret = Ops.get_string(Udba.Summary, 0, "")
      # Reset configuration
      elsif @func == "Reset"
        Udba.Import({})
        @ret = {}
      # Change configuration (run AutoSequence)
      elsif @func == "Change"
        @ret = UdbaAutoSequence()
      # Import configuration
      elsif @func == "Import"
        @ret = Udba.Import(@param)
      # Return actual state
      elsif @func == "Export"
        @ret = Udba.Export
      # Return needed packages
      elsif @func == "Packages"
        @ret = Udba.AutoPackages
      # Read current state
      elsif @func == "Read"
        Yast.import "Progress"
        @progress_orig = Progress.set(false)
        @ret = Udba.Read
        Progress.set(@progress_orig)
      # Write givven settings
      elsif @func == "Write"
        Yast.import "Progress"
        @progress_orig = Progress.set(false)
        Udba.SetWriteOnly(true)
        @ret = Udba.Write
        Progress.set(@progress_orig)
      # did configuration changed
      # return boolean
      elsif @func == "GetModified"
        @ret = Udba.Modified
      # set configuration as changed
      # return boolean
      elsif @func == "SetModified"
        Udba.SetModified(true)
        @ret = true
      else
        Builtins.y2error("Unknown function: %1", @func)
        @ret = false
      end

      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("Udba auto finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret) 

      # EOF
    end
  end
end

Yast::UdbaAutoClient.new.main
