# transport
A public transit app that can calculate routes and show upcoming departures, among a variety of other features. 
The app is an almost pixel-perfect clone of the legacy MVG Fahrinfo app, which has been retired in favor of a new app with a different design.


## Privacy
- Map tiles are loaded from Protomaps (unless local tiles are used).
- Fonts for the map are always loaded from the github.io CDN.
- Transit data API requests are made to the MVG API (see below).


## Transit Data Source (MVG API)
All transit data is requested from APIs of the Münchner Verkehrsgesellschaft mbH (MVG).
The following are excerpts from the [MVG website](https://www.mvg.de/impressum.html) as of the time of this writing :

> Fahrplanauskünfte (Verbindungen)
> 
> 
> 
> Fahrplanauskünfte (Verbindungen) werden durch die Münchner Verkehrs- und Tarifverbund GmbH (MVV) zur Verfügung gestellt und für das Stadtgebiet teilweise mit Livedaten der Münchner Verkehrsgesellschaft mbH (MVG) und der S-Bahn München ergänzt.
> 
> 
> 
> Alle Angaben in der Verbindungsauskunft ohne Gewähr!


> Unsere Systeme dienen der direkten Kundeninteraktion. Die Verarbeitung unserer Inhalte oder Daten durch Dritte erfordert unsere ausdrückliche Zustimmung. Für private, nicht-kommerzielle Zwecke, wird eine gemäßigte Nutzung ohne unsere ausdrückliche Zustimmung geduldet. Jegliche Form von Data-Mining stellt keine gemäßigte Nutzung dar. Wir behalten uns vor, die Duldung grundsätzlich oder in Einzelfällen zu widerrufen. Fragen richten Sie bitte gerne an: redaktion@mvg.de


Please make sure you understand and abide with the usage terms for this API before using it (including through the code in this repository).

The app is in principle designed such that other transit data sources could be used, but the MVG API is the only one that has been implemented so far.

## Web
The app does not correctly work on the web, since the used API does not support CORS. For development purposes, a CORS proxy at localhost:8000 can be used.

## Asset licenses
### Transportation mode icons
Public domain (from Wikicommons)
### Material icons
E.g. the  "man" icon used for the vehicle occupancy indicator.
Material icons are licensed under the Apache License Version 2.0 (https://developers.google.com/fonts/docs/material_icons#licensing)
### Map icons spritesheet
From the [OSM Bright GL Style](https://github.com/openmaptiles/osm-bright-gl-style/blob/master/LICENSE.md), licensed under CC-BY 4.0
### MVV Stops Data
Derived from a dataset of Münchner Verkehrs- und Tarifverbund GmbH (MVV), licensed under CC BY 4.0, https://opendata.muenchen.de/dataset/haltestellen-mit-tarifzuordnung-mvv
### Map style
The map style is based on the protomaps basemap style, licensed as CC0, https://github.com/protomaps/basemaps

### Fonts
NotoSans Condensed: SIL OPEN FONT LICENSE Version 1.1  https://fonts.google.com/noto/specimen/Noto+Sans/license