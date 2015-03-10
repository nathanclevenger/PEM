require 'fastlane_core'

module PEM
  class Options
    def self.available_options
      @@options ||= [
        FastlaneCore::ConfigItem.new(key: :development,
                                     env_name: "PEM_DEVELOPMENT",
                                     description: "Renew the development push certificate instead of the production one",
                                     is_string: false),
        FastlaneCore::ConfigItem.new(key: :generate_p12,
                                     env_name: "PEM_GENERATE_P12_FILE",
                                     description: "Generate a p12 file additionally to a PEM file",
                                     is_string: false),
        FastlaneCore::ConfigItem.new(key: :save_private_key,
                                     short_option: "-s",
                                     env_name: "PEM_SAVE_PRIVATEKEY",
                                     description: "Set to save the private RSA key in the current directory",
                                     is_string: false),
        FastlaneCore::ConfigItem.new(key: :app_identifier,
                                     short_option: "-a",
                                     env_name: "PEM_APP_IDENTIFIER",
                                     description: "The bundle identifier of your app",
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier)),
        FastlaneCore::ConfigItem.new(key: :username,
                                     short_option: "-u",
                                     env_name: "PEM_USERNAME",
                                     description: "Your Apple ID Username",
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:apple_id),
                                     verify_block: Proc.new do |value|
                                       CredentialsManager::PasswordManager.shared_manager(value)
                                     end),
        FastlaneCore::ConfigItem.new(key: :team_id,
                                     short_option: "-t",
                                     env_name: "PEM_TEAM_ID",
                                     description: "The ID of your team if you're in multiple teams",
                                     optional: true,
                                     verify_block: Proc.new do |value|
                                        ENV["FASTLANE_TEAM_ID"] = value
                                     end),
      ]
    end
  end
end
