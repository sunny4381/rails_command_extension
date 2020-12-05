require "rails/command"
require_relative '../user/user_command'
require_relative '../micropost/micropost_command'

module SampleApp
  module Command
    class MainCommand < Rails::Command::Base
      namespace "sample_app"
      @command_name = "sample_app"

      subcommand "user", SampleApp::Command::UserCommand
      subcommand "micropost", SampleApp::Command::MicropostCommand
    end
  end
end
