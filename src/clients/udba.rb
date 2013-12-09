# encoding: utf-8

# File:	clients/udba.ycp
# Package:	Universal Driver Build Assistant
# Summary:	Main file
# Authors:	Boris Manojlovic <boris@steki.net>
#
# $Id: udba.ycp $
#
# Main file for udba configuration. Uses all other files.
module Yast
  class UdbaClient < Client
    def main
      Yast.import "UI"
      Yast.import "Pkg"

      #**
      # <h3>Universal Driver Build Assistant</h3>

      textdomain "udba"

      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("Udba module started")

      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Summary"

      Yast.import "CommandLine"
      Yast.include self, "udba/wizards.rb"

      @cmdline_description = {
        "id"         => "udba",
        # Command line help text for the Xudba module
        "help"       => _(
          "Universal Driver Build Assistant"
        ),
        "guihandler" => fun_ref(method(:UdbaSequence), "any ()"),
        "initialize" => fun_ref(Udba.method(:Read), "boolean ()"),
        "finish"     => fun_ref(Udba.method(:Write), "boolean ()"),
        "actions" =>
          # FIXME TODO: fill the functionality description here
          {},
        "options" =>
          # FIXME TODO: fill the option descriptions here
          {},
        "mappings" =>
          # FIXME TODO: fill the mappings of actions and options here
          {}
      }

      # is this proposal or not?
      @propose = false
      @args = WFM.Args
      if Ops.greater_than(Builtins.size(@args), 0)
        if Ops.is_path?(WFM.Args(0)) && WFM.Args(0) == path(".propose")
          Builtins.y2milestone("Using PROPOSE mode")
          @propose = true
        end
      end

      # main ui function
      @ret = nil

      if @propose
        @ret = UdbaAutoSequence()
      else
        @ret = CommandLine.Run(@cmdline_description)
      end
      Builtins.y2debug("ret=%1", @ret)

      # Finish
      Builtins.y2milestone("Udba module finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret) 

      # EOF
    end
  end
end

Yast::UdbaClient.new.main
