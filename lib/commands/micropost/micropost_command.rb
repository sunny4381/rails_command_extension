module SampleApp
  module Command
    class MicropostCommand < Rails::Command::Base
      desc "list", "list microposts."
      def list
        require_application_and_environment!

        say
        say "#{'Name'.ljust(14)}  #{'Content'.ljust(14)}  Created At"
        say "-" * 80

        Micropost.all.each do |post|
          say "#{post.user.name.ljust(14)}  #{post.content.ljust(14)}  #{post.created_at.iso8601}"
        end
      end
    end
  end
end
