####
#
# A gem for uploading documents to google drive and downloading their exported
# formats: html, plain/text
#
#
####

require 'open-uri'
require 'google/api_client'

class GDoc
    attr_accessor :exports, :response

    def initialize( response, api )
        @response = response
        @exports = response.data.to_hash['exportLinks']
        @api = api
    end

    def make_getters ( *links )
        # create a getter for each of a list of export links
        links.each do |link|
            self.class_eval("def #{link};@#{link};end")
        end
    end

    def list
        @exports.keys
    end

    def download ( type )
        if @exports.keys.include? type

            fp = @api.client.execute(:uri => @exports[type])
            return fp.body

            #open(dest_file, 'wb') do |file|
            #  file << fp.body
            #end
        end
    end

end


class GDriveAPI
    attr_accessor :client, :drive

    def initialize( scope, issuer, p12_path )
        @OAUTH_SCOPE = scope
        @ISSUER = issuer
        @P12_PATH = p12_path

        google_authorize
    end

    def google_authorize
        # creates self.@client and self.@drive objects for making
        @client = Google::APIClient.new(options={application_name:"test", application_version:"v0.0.0"})
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

    def detect_mimetype ( file )
        # use the unix `file` program to get the mimetype of the file
        %x<file --mime-type '#{file}'>.split(':')[1].strip()
        # check success with $?.success? (perlism)
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
      response = @client.execute(
        :api_method => @drive.files.insert,
        :body_object => resource,
        :media => media,
        :parameters => {
          'uploadType' => 'multipart',
          'convert' => true,
          'alt' => 'json'})
      return GDoc.new(response, self)
    end

    def upload_files ( *files )
        # TODO loop over files and pass them to self.upload
        files.each do |f|
          # I expect ruby to return a list of results from this loop via yield
          # somehow it expects to only be run from a block? Why doesn't this curry
          # to an array?
          yield upload(f)
        end
    end

end
