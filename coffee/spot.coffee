###############################################################################
## @---	01/16/2013	Y.Ochi	Initial version                                  ##
###############################################################################
class Spot
  constructor: (name, latlng)->
    @name = name
    @count = 1
    @latlng = latlng
    
    @marker = null
    @balloon = null
    @balloonFn = null
    @IsBalloonOpened = true

  renderContext: ->
    {
      spot_name: @name
      spot_count: @count
    }
    
  infoHtml: ->
    template = Handlebars.compile($('#info-window-template').html())
    template(@renderContext())
    
  createInfoHtml: ()->
    @balloon = new google.maps.InfoWindow({content: @infoHtml()})
    
    
class Spots
  constructor: (gmap)->
    @spots = []
    @gmap = gmap
    
  addSpot: (item) ->
    latlng = item.latlng()
    id = item.item.places[0].id
    if latlng?
      if !@spots[id]?
        @spots[id] = new Spot(item.item.places[0].name, latlng)
      else  
        @spots[id].count++
        
  placeMarkers: ->
    for key, spot of @spots
      spot.marker = new google.maps.Marker(
        {
          position: spot.latlng
          map: @gmap
        }
      )
      spot.createInfoHtml()
      @bindBalloonToMarker key
      
  bindBalloonToMarker: (index) -> 
    spot = @spots[index]
    spot.balloonFn = =>
      if spot.IsBalloonOpened  # when balloon pops
        # Hide other markers
        for key, hiddenSpot of @spots
          if key != index
            hiddenSpot.marker.setVisible(false)
        # Hide other lists
        $('.entry').each ->
          id = $(this).data("spot-id")
          if id != parseInt(index)
            $(this).hide()

        spot.balloon.open(@gmap, spot.marker)    
        spot.IsBalloonOpened = false
      
        $('#clear_select').show(500)
        $('#clear_select').bind 'click', (event) =>
          @clearSelect()
        
      else  # when balloon hides
        # Show other markers
        for key, showSpot of @spots
          showSpot.marker.setVisible(true)
        # Show other lists
        $('.entry').each ->
          $(this).show()
        spot.balloon.close()
        spot.IsBalloonOpened = true 
        $('#clear_select').hide()
        
    google.maps.event.addListener spot.marker, 'click', spot.balloonFn
    
  clearSelect: ->
    for key, spot of @spots
      #hide balloons
      spot.balloon.close?()
      spot.IsBalloonOpened = true
      #show markers
      spot.marker.setVisible(true)
    
    # Show lists
    $('.entry').each ->
      $(this).show()

    $('#clear_select').hide()
    
  clear: ->
    for spot in @spots
      spot.marker.setMap(null)