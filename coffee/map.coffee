###############################################################################
## @---	12/24/2012	Y.Ochi	Initial version                                  ##
###############################################################################
 
class Map
  # _instance = undefined
  
  # #Call map with get whenever you need the instance
  # @get: (latlng = new google.maps.LatLng(INIT_LATITUDE,INIT_LONGTITUDE)) ->
    # if _instance?
      # _instance.setCenter(latlng)
    # else
      # _instance = new Map(latlng)
    # _instance

  # setCenter: (latlng) ->
    # @gmap.setCenter(latlng)
    
  constructor: (latlng= new google.maps.LatLng(INIT_LATITUDE,INIT_LONGTITUDE), zoom=DEFAULT_ZOOM_LEVEL) ->
    #Prepare map
    myOptions = {
      zoom: zoom
      center: latlng
      mapTypeId: google.maps.MapTypeId.ROADMAP
      scrollwheel: false
      scaleControl: true
    }
    @gmap = new google.maps.Map(document.getElementById('map_canvas'), myOptions)
    

  load: (latlng = @gmap.getCenter()) -> 
    read_nearby_popular_with_current_map_range = =>
      bounds = @gmap.getBounds()
      if bounds?
        dist = google.maps.geometry.spherical.computeDistanceBetween(bounds.getNorthEast(), bounds.getSouthWest())
      else
        setTimeout(read_nearby_popular_with_current_map_range, 1000)
    read_nearby_popular_with_current_map_range()

  gotoPlace:(zoom=DEFAULT_ZOOM_LEVEL, latlng= new google.maps.LatLng(INIT_LATITUDE,INIT_LONGTITUDE)) ->
    @gmap.setCenter(latlng)
    @gmap.setZoom(zoom)