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

  constructor: (latlng, zoom=SEARCH_ZOOM_LEVEL) ->
    #initialize
    @markers = []
    @openGroupedInfoWindowFn = {}
    @zorder = 0 
    @loaded_data = null
    @grouped_marker_array = []
    
    #Prepare map
    myOptions = {
      zoom: zoom
      center: latlng
      mapTypeId: google.maps.MapTypeId.ROADMAP
      scrollwheel: false
    }
    
    @gmap = new google.maps.Map(document.getElementById('map_canvas'), myOptions)

    template = Handlebars.compile($('#refresh-control-template').html())
    control = $(template({}))[0]
    google.maps.event.addDomListener(control, 'click', =>
      @load()
    )
    @gmap.controls[google.maps.ControlPosition.TOP_RIGHT].push(control)


  setCenter: (latlng) ->
    @gmap.setCenter(latlng)


  createGroupedMarkers: (new_item) ->
    latlng = new_item.latlng()
    if latlng?
      for grouped_marker in @grouped_marker_array
        if(grouped_marker.item_array[0]? && grouped_marker.item_array[0].item.places[0].id == new_item.item.places[0].id)
          grouped_marker.item_array.push(new_item)	  
          pushed = true
  
      if !pushed
        grouped_marker = new GroupedMarker
        grouped_marker.item_array.push(new_item)
        @grouped_marker_array.push(grouped_marker)

  #Marker
  showGroupedMarkers: ->
    for grouped_marker, num_m in @grouped_marker_array
      latlng = grouped_marker.item_array[0].latlng()
      marker = new google.maps.Marker(
        {
          position: latlng
          map: @gmap
        }
      )
      for item, num_i in grouped_marker.item_array
        offset = new google.maps.Size(0,BALLOON_OFFSET * num_i)
        item.createInfoHtml(offset)
      @bindBalloonToMarker num_m, marker

  bindBalloonToMarker: (index, marker) ->
    @openGroupedInfoWindowFn[index] = =>
      if @grouped_marker_array[index].openedInfoWindows
        for item in @grouped_marker_array[index].item_array
          item.infoWindow.open(@gmap, marker)
          item.infoWindow.setZIndex(@zorder--)
          @grouped_marker_array[index].openedInfoWindows = false
      else
        for item in @grouped_marker_array[index].item_array
          item.infoWindow.close()
          @grouped_marker_array[index].openedInfoWindows = true
    google.maps.event.addListener marker, 'click', @openGroupedInfoWindowFn[index]
    @markers.push(marker)

  getGroupedMarkerIndex: (item_id) ->
    for grouped_marker, num_m in @grouped_marker_array
      for grouped_item in grouped_marker.item_array
        if grouped_item.item.id == item_id then return num_m
    return 0

  clearMarkers: ->
    for item in @loaded_data.items
      if item.infoWindow?
        item.infoWindow.close()
        item.infoWindow = null

    for marker in @markers
      marker.setMap(null)
      
    @markers = []
    @openGroupedInfoWindowFn = {}

  load: (latlng = @gmap.getCenter()) -> 
    console.log("load")
	
    result_div = $('#search-result')
    result_div.empty()
    result_div.html("<div class='loading-text'>Loading...</div>")

    read_nearby_popular_with_current_map_range = =>
      bounds = @gmap.getBounds()
      if bounds?
        console.log bounds.toString()
        dist = google.maps.geometry.spherical.computeDistanceBetween(bounds.getNorthEast(), bounds.getSouthWest())
        
        read_user_follow_items (data) =>
          console.log("data loaded")
          console.log(data)  
          @loaded_data = data;
          @update();
      else
        setTimeout(read_nearby_popular_with_current_map_range, 1000)
    read_nearby_popular_with_current_map_range()


  update: (target = ".*", category = ".*", word = ".*") ->
    console.log("update")
    result_div = $('#search-result')
    result_div.empty()

    @clearMarkers()
    @grouped_marker_array = []
    @zorder = 0
	
    if !@loaded_data? then return

    for item in @loaded_data.items
      item_instance = new Item item

      #Search
      bTitle = item.title.match(new RegExp(target)) && item.title.match(new RegExp(category)) && item.title.match(new RegExp(word))
      bDescription = item.description.match(new RegExp(target)) && item.description.match(new RegExp(category)) && item.description.match(new RegExp(word)) 
      if !(bTitle || bDescription) then continue 
			
      result_div.append(item_instance.html())
      @createGroupedMarkers(item_instance)
      @showGroupedMarkers() 
      
    $('.entry').bind 'click', (event) =>
      item_id = $(event.currentTarget).data('item-id')
      @openGroupedInfoWindowFn[@getGroupedMarkerIndex(item_id)]()

class GroupedMarker
  constructor: ->
    @item_array = []
    @openedInfoWindows = true

