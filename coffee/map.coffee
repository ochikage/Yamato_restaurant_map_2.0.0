###############################################################################
## @---	12/24/2012	Y.Ochi	Initial version                                  ##
###############################################################################
 
class Map
  _instance = undefined
  
  #Call map with get whenever you need the instance
  @get: (latlng = new google.maps.LatLng(INIT_LATITUDE,INIT_LONGTITUDE)) ->
    if _instance?
      _instance.setCenter(latlng)
    else
      _instance = new Map(latlng)
    _instance

  setCenter: (latlng) ->
    @gmap.setCenter(latlng)
    
  constructor: (latlng, zoom=SEARCH_ZOOM_LEVEL) ->
    #Prepare map
    myOptions = {
      zoom: zoom
      center: latlng
      mapTypeId: google.maps.MapTypeId.ROADMAP
      scrollwheel: false
    }
    @gmap = new google.maps.Map(document.getElementById('map_canvas'), myOptions)
    
    @spots = new Spots(@gmap)
    @loaded_data = null


  load: (latlng = @gmap.getCenter()) -> 
    result_div = $('#search-result')
    result_div.empty()
    result_div.html("<div class='loading-text'>Loading...</div>")

    read_nearby_popular_with_current_map_range = =>
      bounds = @gmap.getBounds()
      if bounds?
        console.log bounds.toString()
        dist = google.maps.geometry.spherical.computeDistanceBetween(bounds.getNorthEast(), bounds.getSouthWest())
        
        read_user_follow_items (data) => 
          @loaded_data = data;
          @update();
      else
        setTimeout(read_nearby_popular_with_current_map_range, 1000)
    read_nearby_popular_with_current_map_range()


  update: (target = ".*", category = ".*", word = ".*") ->
    result_div = $('#search-result')
    result_div.empty()

    @clear()
	
    if !@loaded_data? then return

    for item in @loaded_data.items
      item_instance = new Item item

      #Search
      bTitle = item.title.match(new RegExp(target)) && item.title.match(new RegExp(category)) && item.title.match(new RegExp(word))
      bDescription = item.description.match(new RegExp(target)) && item.description.match(new RegExp(category)) && item.description.match(new RegExp(word)) 
      if !(bTitle || bDescription) then continue 
			
      result_div.append(item_instance.html())
      @spots.addSpot(item_instance)
      @spots.placeMarkers()
      
    $('.item_title').bind 'click', (event) =>
      spot_id = $(event.currentTarget).parents("li.entry").data('spot-id')
      @spots.spots[spot_id].balloonFn()

  clear: ->
    for item in @loaded_data.items
      if item.infoWindow?
        item.infoWindow.close()
        item.infoWindow = null
        
    @spots.clear