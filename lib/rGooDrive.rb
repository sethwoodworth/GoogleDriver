####
#
# A gem for uploading documents to google drive and downloading their exported
# formats: html, plain/text
#
#
####
require 'open-uri'
require 'google/api_client'


class GdriveFile
    # TODO refactor this into:
    #   an api handler
    #   an uploaded file class

    def initialize( scope, issuer, p12_path )


        @files = []
        @OAUTH_SCOPE = scope
        @ISSUER = issuer
        @P12_PATH = p12_path
    end

    def detect_mimetype ( file )
        # use the unix `file` program to get the mimetype of the file
        %x<file --mime-type #{file}>.split(':')[1].strip()
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

    # ::file            path to a file you wish to upload [REQUIRED]
    # ::title           title of the document for browsing on google drive
    # ::description     description of the document for browsing on google drive
    def upload (file, title="A document", description="Words, words, words")
      # TODO check for auth status, else: re-auth
      # TODO make init vars for title & desc & file!

      resource = @drive.files.insert.request_schema.new({
        'title' => title,
        'description' => description
      })

      mimetype = detect_mimetype(file)

      media = Google::APIClient::UploadIO.new(file, mimetype)

      # TODO refactor this to return an UploadedFile object
      @result = @client.execute(
        :api_method => @drive.files.insert,
        :body_object => resource,
        :media => media,
        :parameters => {
          'uploadType' => 'multipart',
          'convert' => true,
          'alt' => 'json'})
    end

    def upload_files ( files )
        # TODO loop over files and pass them to self.upload
    end

    def download ( type, dest_file )
        # TODO download should be on the resulting file object
        # TODO check for download `type` before downloading
        links = @result.data.to_hash['exportLinks']
        if links.keys.include? type
            puts "yes, that type is available"

            # TODO don't save to file by default, expose result(s)
            open(dest_file, 'wb') do |file|
              fp = @client.execute(:uri => links['text/html'])
              file << fp.body
            end
        end
    end


    def test
        puts self.detect_mimetype
        self.google_authorize
        self.upload()
        puts @result.body
        self.download('text/html', 'foobie.html')
    end

end
