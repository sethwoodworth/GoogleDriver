require 'open-uri'
require 'google/api_client'


class GdriveFile

    def initialize(scope, issuer, p12_path, file )

        # TODO: move file handling to self.upload()
        @file_path = file
        # TODO if file is a list, do this for all files


        @files = []
        @OAUTH_SCOPE = scope
        @ISSUER = issuer
        @P12_PATH = p12_path
    end

    def detect_mimetype
        # use the unix `file` program to get the mimetype of the file
        %x<file --mime-type #{@file_path}>.split(':')[1].strip()
        # check success with $?.success? (perlism)
    end

    def google_authorize
        # creates self.@client and self.@drive objects for making
        @client = Google::APIClient.new
        @drive = @client.discovered_api('drive', 'v2')

        # Create a new server<>server based API client
        key = Google::APIClient::KeyUtils.load_from_pkcs12(@P12_PATH, 'notasecret')

        # Request Auth
        @client.authorization = Signet::OAuth2::Client.new(
            :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
            :audience => 'https://accounts.google.com/o/oauth2/token',
            :scope => @OAUTH_SCOPE,
            :issuer => @ISSUER,
            :signing_key => key)

        @client.authorization.fetch_access_token!
    end

    def upload
      # TODO check for auth status, else: re-auth
      # TODO make init vars for title & desc

      resource = @drive.files.insert.request_schema.new({
        'title' => 'My document',
        'description' => 'A test document'
      })

      mimetype = detect_mimetype()

      media = Google::APIClient::UploadIO.new(@file_path, mimetype)
      @result = @client.execute(
        :api_method => @drive.files.insert,
        :body_object => resource,
        :media => media,
        :parameters => {
          'uploadType' => 'multipart',
          'convert' => true,
          'alt' => 'json'})
    end

    def download ( type, dest_file )
        # TODO: check for download `type` before downloading
        links = @result.data.to_hash['exportLinks']
        if links.keys.include? type
            puts "yes, that type is available"

            open(dest_file, 'wb') do |file|
              fp = @client.execute(:uri => links['text/html'])
              file << fp.body
            end
        end
    end


    def test
        puts @OAUTH_SCOPE
        puts @ISSUER
        puts self.detect_mimetype
        self.google_authorize
        self.upload()
        puts @result.body
        self.download('text/html', 'foobie.html')
    end

end

