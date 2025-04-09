# ITCS3050-Capstone-Project

NeighborGood

Table of Contents:

Overview
Product Spec
Wireframes
Schema

Overview
Description
This application will be used by people actively looking to purchase a home to check whether the neighborhood the home is located in is safe or not. The application assists the user to determine neighborhood safety by using local public data such as crime/incident reports and county property records. This application is specific to Mecklenburg County only.

App Evaluation

Category: Real Estate / Safety

Mobile: Maps and location services, but app is limited to Mecklenburg county only

Story: As a prospective homebuyer, I want to quickly assess the safety and overall quality of a neighborhood so that I can feel confident in my investment decisions. With NeighborGood Check, I can access public data to see crime trends, review property records, and get an insight into what the residents of the neighborhood will typically deal with. I can also get deeper insights based on publically available data on individuals, along with the general areas

Market: Targeted at individuals and families actively in the home-buying market, including first-time buyers, real estate investors, and anyone concerned about neighborhood safety.

Habit: Users will routinely check neighborhood data during property searches and may use the app repeatedly to compare different areas over time

Scope: This app is technically challenging due to relying on multiple data sources, as well as using one data source to retrieve another. Along with data constraints, there are also challenges as to identifying how to correctly calculate trends that would be meaningful to a user, and deciding what should be displayed and what should not.

Product Spec
1. User Stories 

As a prospective homebuyer, I want to quickly assess the safety and overall quality of a neighborhood so that I can feel confident in my investment decisions. With NeighborGood Check, I can access public data to see crime trends, review property records, and get an insight into what the residents of the neighborhood will typically deal with. I can also get deeper insights based on publically available data on individuals, along with the general areas

2. Screen Archetypes
-Search Page - neighborhood search based on name or location services
-Data dashboard - displays data


3. Navigation

-Search
-Map(Maybe, If I can figure out how to implement it will with the data)
-Overview dashboard
-Detailed Dashboard

Flow Navigation (Screen to Screen)

-Search
-Navigates to results

-Results
-Navigates to Overview dashboard

-Overview dashboard
-Navigates to detailed overview



Wireframes

![App Screenshot](NeighborGood/Assets/wireframes)


Networking

Mecklenburg county property search
-https://property.spatialest.com/nc/mecklenburg/api/v2/search

Mecklenburg county sherrifs dept.
-https://mecksheriffweb.mecklenburgcountync.gov/Arrest/_Search?

ArcGis Mecklenburg county crime and incident report data
-https://gis.charlottenc.gov/arcgis/rest/services/CMPD/CMPDIncidents/MapServer/0/query?outFields=*&where=1%3D1&f=geojson


FEATURES

-Search
search autofill with local government data from public records

-location search
-search user location based on device

-Retrieve crime statistics/data and display a dashboard with trends and statistics

-Provide a more detailed dashboard if data is available

Sprints:
Sprint 1: UI and search
Sprint 2: retrieve data from multiple sources and create method of identifying trends
Sprint 3: Create Overview dashboard to display results, general overview
Sprint 4: create detailed dashboard to allow user to dig deeper into data presented in overview



SUMMARY

Currently working on designing and implementing functional UI as well as search and search autofill feature.
    


