{EventEmitter} = require "events"

assert = require "assert"

BASE=65521      # largest prime smaller than 65536
NMAX=5552       # largest n such that 255n(n+1)/2 + (n+1)(BASE-1) <= 2^32-1
OFFS=1          # default initial s1 offset

ROLLSUM_CHAR_OFFSET = 31

# class Adler32 extends EventEmitter
#
#
#   constructor: (@windowSize, @needleArray) ->
#     @count = 0
#     @a = 0
#     @b = 0
#     @s = new Uint32Array 2
#
#     @pos = 0
#
#     if @windowSize
#       @buf = new Buffer @windowSize
#       @arr = []
#       # @needles = new Uint8Array
#       @needles = {}
#       if @needleArray.length
#         for n in @needleArray
#           @needles[n] = true
#     else
#       @update = (data) ->
#         for byte in data
#           @s[0] += byte + ROLLSUM_CHAR_OFFSET
#           @s[1] += @s[0]
#         @_digest = (@s[1] << 16) | (@s[0] & 0xffff)
#
#   update: (data) ->
#
#     for byte in data
#
#       if @pos < @windowSize
#         # Just rollin and fill the window
#         @s[0] += byte + ROLLSUM_CHAR_OFFSET
#         @s[1] += @s[0]
#         @count += 1
#         @buf[@pos] = byte
#
#         # @arr.push byte
#       else
#         # Start rotating
#
#         inPos = @pos % @windowSize
#         outPos = (@pos + @windowSize) % @windowSize
#         byteOut = @buf[outPos]
#         # byteOut = @arr.shift()
#
#         @s[0] += (byte) - (byteOut)
#         @s[1] += @s[0] - @count * (byteOut + ROLLSUM_CHAR_OFFSET)
#
#         @buf[inPos] = byte
#         # @arr.push byte
#
#       @_digest = (@s[1] << 16) | (@s[0] & 0xffff)
#       console.log "now is", @windowToString(), @s[0], @s[1], @hexdigest(), @digest()
#       @pos += 1
#
#       if @needles[@_digest]
#         @emit "found",
#           digest: @_digest
#           position: @pos - @windowSize
#
#
#   digest: -> @_digest
#   hexdigest: -> @_digest.toString 16
#   windowToString: ->
#     s = for byte in @arr
#       String.fromCharCode byte
#     s.join ""




class Adler32 extends EventEmitter

  constructor: (@windowSize, needles) ->
    @count = 0
    @a = OFFS
    @b = 0

    @needles = {}

    if @windowSize
      for n in needles
        console.log "searching for", n, n.toString(16)
        @needles[n.toString 10] = 1

      @buf = new Buffer @windowSize
      @arr = []
    else
      @update = (data) ->
        for byte in data
          @a = @a + byte
          @b = @b + @a
          @a %= BASE
          @b %= BASE
        @_digest = (@b << 16) | @a

    @pos = 0

  update: (data) ->
    for byte in data
      if @pos < @windowSize
        # Just rollin and fill the window
        @a = @a + byte
        @b = @b + @a
        @a %= BASE
        @b %= BASE

        @count += 1
        @buf[@pos] = byte
        # @arr.push byte
      else
        # Start rotating

        inPos = @pos % @windowSize
        outPos = (@pos + @windowSize) % @windowSize
        byteOut = @buf[outPos]
        # assert.equal byteOut, @arr.shift()

        @a += byte - byteOut
        @b += @a - @count * byteOut - OFFS
        @a %= BASE
        @b %= BASE

        @buf[inPos] = byte
        # @arr.push byte

      @pos += 1
      @_digest = ((@b << 16) | @a).toString 10

      # console.log "now", @toString(), @hexdigest()

      if @needles[@_digest]
        @emit "found",
          digest: @_digest
          position: @pos - @windowSize



  digest: -> @_digest
  hexdigest: -> @_digest.toString 16

  toString: ->
    s = for byte in @arr
      String.fromCharCode byte
    s.join ""

exports.Adler32 = Adler32



if require.main is module
  fs = require "fs"
  stream = fs.createReadStream "/home/epeli/media/Tron.avi"

  a = new Adler32 1024*2, [ 1245, 324324 ]
  # a = new Adler32

  size = 0
  start = Date.now()
  i = setInterval update = ->

    diff = (Date.now() - start) / 1000

    megabytes = size / 1024 / 1024
    console.log "#{ megabytes / diff } MB/s. #{ megabytes }MB in #{ diff }s"
  , 1000

  stream.on "data", (data) ->
    a.update data
    size += data.length

  stream.on "end", ->
    clearInterval i
    update()
    console.log "done", a.digest(), a.hexdigest()
    console.log "Right 42b93f18"











