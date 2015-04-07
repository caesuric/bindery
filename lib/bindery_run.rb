require_relative 'bindery'

source = ARGV[0] || 'c:\Users\Illusory\Desktop\ariagne\ariagne.html'
destination = ARGV[1] || 'c:\Users\Illusory\Desktop\ariagne\ariagne_output.html'
bindery = Bindery.new(source,destination)