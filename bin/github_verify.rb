#!/usr/bin/env ruby

# github_verify.rb
#
# A straightforward implementation of Github webhook verification, as
# explained at https://developer.github.com/webhooks/securing/, but
# for use in Cog pipelines triggered via webhook.

require 'json'
require 'openssl'

# Obtain the checksum from the webhook request header. All headers are
# available from the command environment
def signature(cog_env)
  header_value = cog_env["headers"]["x-hub-signature"]
  header_value.sub("sha1=", "")
end

# Compute our own checksum by hashing the raw body of the request with
# our shared secret
def compute_signature(cog_env, secret)
  body = cog_env["raw_body"]
  OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), secret, body)
end

# Borrowed from Rack.Utils.secure_compare
def secure_compare(a, b)
  return false unless a.bytesize == b.bytesize

  l = a.unpack("C*")

  r, i = 0, -1
  b.each_byte { |v| r |= v ^ l[i+=1] }
  r == 0
end

# Read the command environment from STDIN
cog_env = JSON.parse(ARGF.read)

# Obtain Github webhook shared secret set up by Cog's dynamic command
# configuration:
# https://github.com/operable/cog/wiki/Dynamic-Command-Configuration
secret = ENV['GITHUB_WEBHOOK_SECRET']

# If GITHUB_WEBHOOK_SECRET isn't log an error message and bail
if secret == nil then
  STDERR.puts "Missing required environment variable $GITHUB_WEBHOOK_SECRET."
  exit 1
end
signature = signature(cog_env)
computed = compute_signature(cog_env, secret)

if secure_compare(signature, computed)
  # Our checksum matches Github's, so we'll simply pass all the data
  # we received downstream to the rest of our pipeline for processing
  STDOUT.puts "JSON"
  STDOUT.puts JSON.generate(cog_env)
else
  # Something isn't right; the checksums don't match, so let's halt
  # pipeline processing now
  STDERR.puts "Signature does not match!"
  exit 1
end
