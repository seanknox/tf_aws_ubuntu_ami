#!/usr/bin/ruby
require 'net/https'
require 'json'

class FetchAmiIds
  RELEASES_TABLE_URL =
    'https://cloud-images.ubuntu.com/locator/ec2/releasesTable'.freeze

  KEYS = [
    :region,
    :suite,
    :version,
    :arch,
    :type,
    :date,
    :ami,
    :aki,
    :launch
  ].freeze

  def self.call
    new.call
  end

  def initialize
    @http = Net::HTTP.new(uri.host, uri.port)
    @http.use_ssl = (uri.scheme == 'https')
  end

  def call
    puts JSON.pretty_generate(output)
  end

  private

  def output
    {
      'variable' => {
        'all_amis' => {
          'description' => 'The AMI to use',
          'default' => formatted_ami_list
        }
      }
    }
  end

  def formatted_ami_list
    keyed_data.map { |hash| "#{hash[:desc]}: #{hash[:ami_id]}" }
  end

  def keyed_data
    data.map do |item|
      KEYS.zip(item).to_h
    end.map do |h|
      {
        desc: "#{h[:region]}-#{h[:suite]}-#{h[:arch]}-#{h[:type]}",
        ami_id: ami_id(h[:ami])
      }
    end
  end

  def data
    @data ||= resp.gsub!("],\n]\n}", ']]}')
    JSON.parse(@data)['aaData']
  end

  def ami_id(string)
    string.gsub(/.*>(ami-\w+)<.*/, '\1')
  end

  def uri
    URI.parse(RELEASES_TABLE_URL)
  end

  def request
    Net::HTTP::Get.new(uri.request_uri)
  end

  def resp
    @http.request(request).body
  end
end

FetchAmiIds.call
