module Puppet::Parser::Functions
  newfunction(:deep_merge, :type => :rvalue, :doc => <<-'ENDHEREDOC') do |args|
    Recursively merges two or more hashes together and returns the resulting hash.

    For example:

        $hash1 = {'one' => 1, 'two' => 2, 'three' => { 'four' => 4 } }
        $hash2 = {'two' => 'dos', 'three' => { 'five' => 5 } }
        $merged_hash = deep_merge($hash1, $hash2)
        # The resulting hash is equivalent to:
        # $merged_hash = { 'one' => 1, 'two' => 'dos', 'three' => { 'four' => 4, 'five' => 5 } }

    When there is a duplicate key that is a hash, they are recursively merged.
    When there is a duplicate key that is not a hash, the key in the rightmost hash will "win."

    ENDHEREDOC

    if args.length < 2
      raise Puppet::ParseError, ("deep_merge(): wrong number of arguments (#{args.length}; must be at least 2)")
    end

    result = Hash.new
    args.each do |arg|
      next if arg.is_a? String and arg.empty? # empty string is synonym for puppet's undef
      # If the argument was not a hash, skip it.
      unless arg.is_a?(Hash)
        raise Puppet::ParseError, "deep_merge: unexpected argument type #{arg.class}, only expects hash arguments"
      end

      # Now we have to traverse our hash assigning our non-hash values
      # to the matching keys in our result while following our hash values
      # and repeating the process.
      overlay( result, arg )
    end
    return( result )
  end
end

def overlay( hash1, hash2 )
    hash2.each do |key, value|
        if( value.is_a?(Hash) )
            if( ! hash1.has_key?( key ) or ! hash1[key].is_a?(Hash))
                hash1[key] = value
            else
                overlay( hash1[key], value )
            end
        else
            hash1[key] = value
        end
    end
end

