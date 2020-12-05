module SampleApp
  module Command
    class UserCommand < Rails::Command::Base
      desc "list", "list users."
      def list
        require_application_and_environment!

        say
        say "#{'Name'.ljust(14)}  #{'Email'.ljust(32)}  Updated At"
        say "-" * 80

        User.all.each do |user|
          say "#{user.name.ljust(14)}  #{user.email.ljust(32)}  #{user.updated_at.iso8601}"
        end
      end
    end
  end
end
