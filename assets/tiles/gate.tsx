<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.8" tiledversion="1.8.4" name="gate" tilewidth="34" tileheight="52" tilecount="5" columns="5" objectalignment="bottom">
 <tileoffset x="0" y="16"/>
 <grid orientation="orthogonal" width="64" height="32"/>
 <properties>
  <property name="Solid" type="bool" value="true"/>
 </properties>
 <image source="gate.png" width="170" height="52"/>
 <tile id="0">
  <objectgroup draworder="index" id="2">
   <object id="22" x="33" y="54">
    <polygon points="3.43354,2.31514 1.30238,-22.184 -35.4864,-36.776 -34.1712,-13.632"/>
   </object>
  </objectgroup>
  <animation>
   <frame tileid="0" duration="50"/>
   <frame tileid="1" duration="50"/>
   <frame tileid="2" duration="50"/>
   <frame tileid="3" duration="50"/>
  </animation>
 </tile>
</tileset>
