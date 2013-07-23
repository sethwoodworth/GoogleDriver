require_relative '../lib/rGooDrive.rb'
require 'yaml'


PRIVATE = YAML::load_file(
            File.join(
                File.dirname(File.expand_path(__FILE__)),
                '../private.yml')
      )

file_doc = "samples/April\ 13.doc"
file_ppt = "samples/Lecture_5.ppt"

describe GDriveAPI do

  before(:each) do
    @api = GDriveAPI.new( PRIVATE['scope'], PRIVATE['issuer'], PRIVATE['p12_path'] )
  end

  after(:each) do
    @api = nil
    # TODO delete any uploaded files
  end

  it "detects the Mime Type of the file to be uploaded" do
    expect(@api.detect_mimetype(file_doc)).to eq('application/msword')
    #expect(@api.modified_on).to eq('Wed, 12 Feb 1997 16:29:51 -0500')
    #expect(@api.filename).to eq('test_doc.doc')
  end

  it "should authorize our Google API client" do
    # This is a poor test.
    # Maybe get the entirety of api.client and check that len > 500 ?
    expect(@api.client.class).to eq(Google::APIClient)
  end

  it "should upload a file" do
    result = @api.upload(file_doc)
    expect(result.class).to eq(GDoc)
  end

  it "should accept multiple file uploads at once" do
    result = @api.upload_files(file_doc, file_ppt)
    expect(result.count).to eq(2)
    expect(result).to eq(2)
  end

end

describe GDoc do


  before(:each) do
    @api = GDriveAPI.new( PRIVATE['scope'], PRIVATE['issuer'], PRIVATE['p12_path'] )
    @gdoc = @api.upload(file_doc)
  end

  it "should have an exports hash with 1 or more keys" do
    expect(@gdoc.exports.keys.count).to be > 2
  end

  it "should have the original response available" do
    expect(@gdoc.response.class).to eq(Google::APIClient::Result)
  end

  it "should list the available export downloads" do
  end

  it "should reject a download if it doesn't recognize the type" do
  end

  it "should return the HTML of an uploaded document" do
  end

end
