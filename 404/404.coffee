# shim layer with setTimeout fallback
window.requestAnimationFrame = (->
  window.requestAnimationFrame or window.webkitRequestAnimationFrame or window.mozRequestAnimationFrame or window.oRequestAnimationFrame or window.msRequestAnimationFrame or (callback) ->
    window.setTimeout callback, 1000 / 60
)()

TOTAL_STARS = 5000
#STAR_COLOR = [245, 170, 68]
STAR_COLOR = [255, 255, 255]

class window.StellarClass
  @frequency:
    O: 0.0000003
    B: 0.0013
    A: 0.006
    F: 0.03
    G: 0.076
    K: 0.121
    M: 0.7645

  @luminosity:
    O: 30000
    B: 27500
    A: 15
    F: 3.25
    G: 1.05
    K: 0.34
    M: 0.08

  # http://www.vendian.org/mncharity/dir3/starcolor/
  @color:
    O: [155, 176, 255]
    B: [170, 191, 255]
    A: [202, 215, 255]
    F: [248, 247, 255]
    G: [255, 244, 234]
    K: [255, 210, 161]
    M: [255, 204, 111]

  @random: =>
    rand = Math.random()
    last = null
    for sclass, val of @frequency
      if rand < val
        return sclass
      last = sclass
    return last

class window.Star
  @tinted_images: {}

  constructor: (props) ->
    for key, val of props
      this[key] = val

    @color = StellarClass.color[@sclass]
    @luminosity = StellarClass.luminosity[@sclass]
    @luminosity += Math.random()*(StellarClass.luminosity[@sclass]/2)
    @luminosity -= Math.random()*(StellarClass.luminosity[@sclass]/2)

    @img = document.getElementById("star#{@sclass}")

class window.Map
  stars: []
  started: false

  mouseX: 0
  mouseY: 0
  twinkle: 1

  last_time: 0
  loop: (timestamp) =>
    dt = (timestamp - @last_time) or 16
    for star in @stars
      shift = 0#(dt*star.speed/50) * -@mouseX/200

      while star.x+shift > @ww
        shift -= @ww
        star.y = Math.random()*@wh

      while star.x+shift < 0
        shift += @ww
        star.y = Math.random()*@wh

      star.x += shift

    @twinkle += dt/650
    @render()
    @last_time = timestamp
    requestAnimationFrame(@loop)

  render: () =>
    @ctx.globalAlpha = 1
    @ctx.fillStyle = "rgb(0,0,0)"
    @ctx.fillRect(0, 0, @ww, @wh)
    for star in @stars
      if star.luminosity > 1
        lumen = 2*Math.log(10*star.luminosity)
      else
        lumen = 10*star.luminosity
      lumen += star.speed/2
      lumen = Math.round(lumen)

      if lumen > 6
        @ctx.globalAlpha = 1
      else
        @ctx.globalAlpha = Math.abs(Math.sin(@twinkle+star.speed))
        #@ctx.globalAlpha = Math.min(@ctx.globalAlpha, Math.max(0, 1-Math.abs(@mouseX+@mouseY)*3/@ww))

      @ctx.drawImage(star.img, Math.floor(star.x-lumen/2), Math.floor(star.y-lumen/2), lumen, lumen)

  resize: =>
    old_ww = @ww; old_wh = @wh
    @ww = window.innerWidth
    @wh = window.innerHeight
    for obj in @stars
      obj.x = obj.x*(@ww/old_ww)
      obj.y = obj.y*(@wh/old_wh)
    @canvas.setAttribute('width', @ww)
    @canvas.setAttribute('height', @wh)
    @render()

  begin: =>
    return if @started
    @canvas = document.getElementById('canvas')
    @ctx = @canvas.getContext("2d")
    @resize()

    for i in [0..TOTAL_STARS]
      if Math.random() < 0.9
        speed = 1+Math.random()*6
      else
        speed = Math.random()*10
      star = new Star(
        #x: @ww/2 + jStat.normal.sample(0,@wh/2)
        #y: @wh/2 + jStat.normal.sample(0,@wh/2)
        x: Math.random()*@ww
        y: Math.random()*@wh
        sclass: StellarClass.random()
        speed: speed
      )
      @stars.push star
    """
    i = 1
    for sclass of StellarClass.frequency
      @stars.push new Star(
        x: i*100
        y: i*100
        speed: 10
        sclass: sclass
      )
      i += 1
    """

    document.onmousemove = (e) =>
      @mouseX = e.pageX - @ww/2
      @mouseY = e.pageY - @wh/2

    window.onresize = @resize
    @loop()
    @started = true

    @mouseX = @ww/2
  setup: =>
    @begin()

ready = (func) ->
  """Hacky $(document).ready() equivalent."""
  # http://stackoverflow.com/questions/799981/document-ready-equivalent-without-jquery 
  if /in/.test(document.readyState)
    setTimeout(ready, 9, func)
  else
    func()

ready ->
  window.map = new Map
  map.setup()
