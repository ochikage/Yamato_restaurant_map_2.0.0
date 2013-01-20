###############################################################################
## @---	01/20/2013	Y.Ochi	Initial version                                  ##
###############################################################################
class Content
  _instance = null
  @get: ->
    if _instance? 
      return _instance
    else
      _instance = new Content
      
  constructor: ()->
    @items = []
    @spots = []
    @map = new Map()
    @list_div = $('#search-result')
    
  load: () -> 
    @list_div.empty()
    @list_div.html("<div class='loading-text'>Loading...</div>")
    
    @map.load()
    
    read_user_follow_items (ret) => 
      for data in ret.items
        @items.push(new Item(data))
      @update();

  update: ->
    @clear()
	
    if @items == null
      return

    for item in @items
      item.setListElement($(item.html()).appendTo(@list_div))
      @addSpot(item)
    @placeMarkers()
      
    $('.item_title').bind 'click', (event) =>
      spot_id = $(event.currentTarget).parents("li.entry").data('spot-id')
      @spots[spot_id].balloonFn()
    
  addSpot: (item) ->
    latlng = item.latlng()
    id = item.getSpotId()
    if latlng?
      if !@spots[id]?
        @spots[id] = new Spot(item.getSpotName(), latlng)
      else  
        @spots[id].count++
        
  placeMarkers: ->
    for key, spot of @spots
      console.log(key)
      spot.marker = new google.maps.Marker(
        {
          position: spot.latlng
          map: @map.gmap
        }
      )
      spot.createInfoHtml()
      @bindBalloonToMarker key
      
  bindBalloonToMarker: (index) -> 
    spot = @spots[index]
    spot.balloonFn = =>
      if spot.IsBalloonOpened  # when balloon pops
        # Hide list
        @setListVisible(false)
        for item in @items
          spot_id = item.getSpotId() 
          if spot_id == parseInt(index)
            item.getListElement().show()
        # Hide marker    
        @setMarkerVisible(false)
        spot.marker.setVisible(true)
        # Open Balloon
        spot.balloon.open(@map.gmap, spot.marker)    
        spot.IsBalloonOpened = false
      
        $('#clear_select').show(500)
        
      else  # when balloon hides
        @setListVisible(true)
        @setMarkerVisible(true)
        spot.balloon.close()
        spot.IsBalloonOpened = true 
        
        $('#clear_select').hide()
        
    google.maps.event.addListener spot.marker, 'click', spot.balloonFn

  getSelect: (category = ".*", word = ".*", distance = Infinity)->
    @setListVisible(false)
    @setMarkerVisible(false)
    
    for item in @items
      bTitle = item.getTitle().match(new RegExp(category)) && item.getTitle().match(new RegExp(word))
      bDescription = item.getDescription().match(new RegExp(category)) && item.getDescription().match(new RegExp(word))
      bDistance = if item.distance < distance then true else false

      @map.gotoPlace(ZOOM_LEVEL[distance])
      
      if (bTitle? || bDescription?) && bDistance
        item.getListElement().show()
        @spots[item.getSpotId()].marker.setVisible(true)
       
    return true
  
  setListVisible:(visible) ->
    for item in @items
      if visible
        item.getListElement().show()
      else
        item.getListElement().hide()
        
  setMarkerVisible: (visible)->
    for key, spot of @spots
      spot.marker.setVisible(visible)
  
  clearSelect: ->
    @map.gotoPlace()
    for key, spot of @spots
      #hide balloons
      spot.balloon.close?()
      spot.IsBalloonOpened = true
      #show markers
      spot.marker.setVisible(true)
    
  clear: ->
    @list_div.empty()
    
    for key, spot of @spots
      spot.marker.setMap(null)
      
    for item in @items
      if item.infoWindow?
        item.infoWindow.close()
        item.infoWindow = null