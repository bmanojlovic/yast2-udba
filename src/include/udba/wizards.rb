# encoding: utf-8

# File:	include/udba/wizards.ycp
# Package:	Universal Driver Build Assistant
# Summary:	Wizards definitions
# Authors:	Boris Manojlovic <boris@steki.net>
#
# $Id: wizards.ycp $
module Yast
  module UdbaWizardsInclude
    def initialize_udba_wizards(include_target)
      Yast.import "UI"
      Yast.import "Pkg"

      textdomain "udba"

      Yast.import "Sequencer"
      Yast.import "Wizard"

      Yast.include include_target, "udba/complex.rb"
      Yast.include include_target, "udba/dialogs.rb"
    end

    # Add a configuration of udba
    # @return sequence result
    def AddSequence
      # FIXME: adapt to your needs
      aliases = { "recipeSelection" => lambda { recipeSelectionDialog }, "buildProcess" => lambda(
      ) do
        buildProcessDialog
      end }

      # FIXME: adapt to your needs
      sequence = {
        "ws_start"        => "recipeSelection",
        "recipeSelection" => { :abort => :abort, :next => "buildProcess" },
        "buildProcess"    => { :abort => :abort }
      }

      Sequencer.Run(aliases, sequence)
    end

    # Main workflow of the udba tool
    # @return sequence result
    def MainSequence
      # FIXME: adapt to your needs
      aliases = { "summary" => lambda { SummaryDialog() }, "configure" => [
        lambda { AddSequence() },
        true
      ] }

      # FIXME: adapt to your needs
      sequence = {
        "ws_start"  => "summary",
        "summary"   => {
          :abort     => :abort,
          :next      => :next,
          :configure => "configure",
          :other     => "configure"
        },
        "configure" => { :abort => :abort, :next => "summary" }
      }

      ret = Sequencer.Run(aliases, sequence)

      deep_copy(ret)
    end

    # Whole configuration of udba
    # @return sequence result
    def UdbaSequence
      aliases = {
        "read"  => [lambda { ReadDialog() }, true],
        "main"  => lambda { MainSequence() },
        "write" => [lambda { WriteDialog() }, true]
      }

      sequence = {
        "ws_start" => "read",
        "read"     => { :abort => :abort, :next => "main" },
        "main"     => { :abort => :abort, :next => "write" },
        "write"    => { :abort => :abort, :next => :next }
      }

      Wizard.CreateDialog

      ret = Sequencer.Run(aliases, sequence)

      UI.CloseDialog
      deep_copy(ret)
    end

    # Whole configuration of udba but without reading and writing.
    # For use with autoinstallation.
    # @return sequence result
    def UdbaAutoSequence
      # Initialization dialog caption
      caption = _("Universal Driver Build Assistant")
      # Initialization dialog contents
      contents = Label(_("Initializing..."))

      Wizard.CreateDialog
      Wizard.SetContentsButtons(
        caption,
        contents,
        "",
        Label.BackButton,
        Label.NextButton
      )

      if Package.InstalledAll(Udba.required_packages) == false
        Package.InstallAll(Udba.required_packages)
      end

      ret = MainSequence()

      UI.CloseDialog
      deep_copy(ret)
    end
  end
end
