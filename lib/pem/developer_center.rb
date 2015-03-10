require 'fastlane_core/developer_center/developer_center'

module FastlaneCore
  class DeveloperCenter
    APP_IDS_URL = "https://developer.apple.com/account/ios/identifiers/bundle/bundleList.action"


    # This method will enable push for the given app
    # and download the cer file in any case, no matter if it existed before or not
    # @return the path to the push file
    def fetch_cer_file(app_identifier, production)
      begin
        open_app_page(app_identifier)

        click_on "Edit"
        wait_for_elements(".item-details") # just to finish loading

        apple_pay_value = first(:css, '#omcEnabled').value
        if apple_pay_value == "on"
          Helper.log.info "Apple Pay for app '#{app_identifier}' is enabled"
        else
          Helper.log.warn "Apple Pay '#{app_identifier}' is disabled. This has to change."
          first(:css, '#omcEnabled').click
          sleep 3 # this takes some time
          create_apple_pay_for_app(app_identifier)
          open_app_page(app_identifier)
          sleep 2
          click_on "Edit"
          sleep 2
          wait_for_elements(".item-details") # just to finish loading
        end

        push_value = first(:css, '#pushEnabled').value
        if push_value == "on"
          Helper.log.info "Push for app '#{app_identifier}' is enabled"
        else
          Helper.log.warn "Push for app '#{app_identifier}' is disabled. This has to change."
          first(:css, '#pushEnabled').click
          sleep 3 # this takes some time
        end

        Helper.log.warn "Creating push certificate for app '#{app_identifier}'."
        create_push_for_app(app_identifier, production)
      rescue => ex
        error_occured(ex)
      end
    end


    private
      def open_app_page(app_identifier)
        begin
          visit APP_IDS_URL
          sleep 5

          wait_for_elements(".toolbar-button.search").first.click
          fill_in "bundle-list-search", with: app_identifier
          sleep 5

          apps = all(:xpath, "//td[@title='#{app_identifier}']")
          if apps.count == 1
            apps.first.click
            sleep 2

            return true
          else
            raise DeveloperCenterGeneralError.new("Could not find app with identifier '#{app_identifier}' on apps page.")
          end
        rescue => ex
          error_occured(ex)
        end
      end

      def create_push_for_app(app_identifier, production)

        element_name = (production ? '.button.small.navLink.distribution.enabled' : '.button.small.navLink.development.enabled')
        begin
          wait_for_elements(element_name).first.click # Create Certificate button
        rescue
          raise "Could not create a new push profile for app '#{app_identifier}'. There are already 2 certificates active. Please revoke one to let PEM create a new one\n\n#{current_url}".red
        end

        sleep 2

        click_next # "Continue"

        sleep 1

        wait_for_elements(".file-input.validate")
        wait_for_elements(".button.small.center.back")

        # Upload CSR file
        first(:xpath, "//input[@type='file']").set PEM::SigningRequest.get_path

        click_next # "Generate"

        while all(:css, '.loadingMessage').count > 0
          Helper.log.debug "Waiting for iTC to generate the profile"
          sleep 2
        end

        certificate_type = (production ? 'production' : 'development')

        # Download the newly created certificate
        Helper.log.info "Going to download the latest profile"

        # It is enabled, now just download it
        sleep 2

        download_button = first(".button.small.blue")
        host = Capybara.current_session.current_host
        url = download_button['href']
        url = [host, url].join('')
        Helper.log.info "Downloading URL: '#{url}'"

        cookieString = ""

        page.driver.cookies.each do |key, cookie|
          cookieString << "#{cookie.name}=#{cookie.value};" # append all known cookies
        end

        data = open(url, {'Cookie' => cookieString}).read

        raise "Something went wrong when downloading the certificate" unless data

        path = "#{TMP_FOLDER}aps_#{certificate_type}_#{app_identifier}.cer"
        dataWritten = File.write(path, data)

        if dataWritten == 0
          raise "Can't write to #{TMP_FOLDER}"
        end

        Helper.log.info "Successfully downloaded latest .cer file to '#{path}'".green
        return path
      end

      def create_apple_pay_for_app(app_identifier)

        begin
          Helper.log.debug "Enabling Apple Pay Support"
          wait_for_elements('.button.small.green.ok').first.click
          sleep 2
          wait_for_elements('.button.small.navLink.enabled').first.click
          sleep 2
          wait_for_elements('#omcList-1')
          first(:css, '#omcList-1').click
          sleep 2
          wait_for_elements('.button.small.blue.right.submit').first.click
          sleep 2
          wait_for_elements('.button.small.blue.right.submit').first.click
          sleep 2
          wait_for_elements('.button.small.center.cancel').first.click
          sleep 2
          Helper.log.debug "Apple Pay Support Successfully Enabled"
        rescue
          raise "Could not enable Apple Pay for app '#{app_identifier}'. \n\n#{current_url}".red
        end

      end

      def click_next
        wait_for_elements('.button.small.blue.right.submit').last.click
      end
  end
end
