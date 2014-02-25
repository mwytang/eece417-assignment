<!DOCTYPE html>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.google.appengine.api.users.User" %>
<%@ page import="com.google.appengine.api.users.UserService" %>
<%@ page import="com.google.appengine.api.users.UserServiceFactory" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreServiceFactory" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreService" %>
<%@ page import="com.google.appengine.api.datastore.Query" %>
<%@ page import="com.google.appengine.api.datastore.Entity" %>
<%@ page import="com.google.appengine.api.datastore.FetchOptions" %>
<%@ page import="com.google.appengine.api.datastore.Key" %>
<%@ page import="com.google.appengine.api.datastore.KeyFactory" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<html>
  <head>
    <link type="text/css" rel="stylesheet" href="/stylesheets/main.css" />
    <script type="text/javascript" src="https://maps.googleapis.com/maps/api/js?key=AIzaSyAnKGB1sVx-WYMoDqgSV-qWuq0n0Wd3r8E&amp;sensor=true" style="">
  </script>
  <script type="text/javascript">
  
      var map;
      var mapOptions = {
          zoom: 8
      };
      var markers = [];
      function initialize() {
        map = new google.maps.Map(document.getElementById("map-canvas"),
            mapOptions);
        setLocations(map);
        if(navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(function(position) {
                var location = position.coords;
                var current = new google.maps.LatLng(position.coords.latitude, position.coords.longitude);
                
                var cur = new google.maps.InfoWindow({
                    map: map,
                    position: current,
                    content: 'You are here.'
                });
                document.getElementById('latitude').value = location.latitude;
                document.getElementById('longitude').value = location.longitude;
                map.setCenter(current);
            }, function() {
              handleNoGeolocation(true);
            });
          } else {
            handleNoGeolocation(false);
          } 
      }
      
      function handleNoGeolocation(errorFlag) {
        if (errorFlag) {
          var content = 'Error: The Geolocation service failed.';
        } else {
          var content = 'Error: Your browser doesn\'t support geolocation.';
        }
      
        var options = {
          map: map,
          position: new google.maps.LatLng(60, 105),
          content: content
        };
      
        var infowindow = new google.maps.InfoWindow(options);
        map.setCenter(options.position);
      }
      
      function addLocation(longitude, latitude, user) {
          var loc = new google.maps.Marker({
              position: new google.maps.LatLng(latitude, longitude),
              title: user,
          });
          markers.push(loc);
      }
      
      function setLocations(map) {
          for (var i = 0; i < markers.length; i++) {
              markers[i].setMap(map);
          }
      }
      
      google.maps.event.addDomListener(window, 'load', initialize);
  </script>
  </head>
  <body>
  <div id="map-canvas"/></div>

<%
    String guestbookName = request.getParameter("guestbookName");
    if (guestbookName == null) {
        guestbookName = "EECE 417";
    }
    pageContext.setAttribute("guestbookName", guestbookName);
    UserService userService = UserServiceFactory.getUserService();
    User user = userService.getCurrentUser();
    if (user != null) {
      pageContext.setAttribute("user", user);
%>
<p>Hello, ${fn:escapeXml(user.nickname)}! (You can
<a href="<%= userService.createLogoutURL(request.getRequestURI()) %>">sign out</a> to stay anonymous.)</p>
<%
    } else {
%>
<p>Hello!
<a href="<%= userService.createLoginURL(request.getRequestURI()) %>">Sign in</a>
to include your name with greetings you post.</p>
<%
    }
%>
<%
    DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
    Key guestbookKey = KeyFactory.createKey("Guestbook", guestbookName);
    // Run an ancestor query to ensure we see the most up-to-date
    // view of the Greetings belonging to the selected Guestbook.
    Query query = new Query("Greeting", guestbookKey).addSort("date", Query.SortDirection.DESCENDING);
    List<Entity> greetings = datastore.prepare(query).asList(FetchOptions.Builder.withLimit(5));
    if (greetings.isEmpty()) {
        %>
        <p>Guestbook '${fn:escapeXml(guestbookName)}' has no messages.</p>
        <%
    } else {
        %>
        <p>Messages in Guestbook '${fn:escapeXml(guestbookName)}'.</p>
        <%
        for (Entity greeting : greetings) {
            pageContext.setAttribute("greeting_content",
                                     greeting.getProperty("content"));
            if (greeting.getProperty("user") == null) {
                pageContext.setAttribute("name", "anonymous");
                %>
                <p>An anonymous person wrote:</p>
                <%
            } else {
                pageContext.setAttribute("greeting_user",
                                         greeting.getProperty("user"));
                pageContext.setAttribute("name", greeting.getProperty("nickname"));
                %>
                <p><b>${fn:escapeXml(greeting_user.nickname)}</b> wrote:</p>
                <%
            }
            if (greeting.getProperty("longitude") == null) {
                pageContext.setAttribute("longitude", "0");   
            } else {
                pageContext.setAttribute("longitude", greeting.getProperty("longitude"));
            }
            if (greeting.getProperty("latitude") == null) {
                pageContext.setAttribute("latitude", "0");   
            } else {
                pageContext.setAttribute("latitude", greeting.getProperty("latitude"));
            }
            %>
            <blockquote>${fn:escapeXml(greeting_content)}</blockquote>
            <p>Longitude: ${fn:escapeXml(longitude)}, Latitude: ${fn:escapeXml(latitude)}</p>
            <script type="text/javascript">
                addLocation(${fn:escapeXml(longitude)}, ${fn:escapeXml(latitude)}, "${fn:escapeXml(name)}");
            </script>
            <%
        }
    }
%>

    <form action="/sign" method="post">
      <div><textarea name="content" rows="3" cols="60"></textarea></div>
      <div><input type="submit" value="Post Greeting" /></div>
      <input type="hidden" name="guestbookName" value="${fn:escapeXml(guestbookName)}"/>
      <input type="hidden" name="longitude" id="longitude" value="0"/>
      <input type="hidden" name="latitude" id="latitude" value="0"/>
    </form>

  </body>
</html>