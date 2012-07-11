# encoding: utf-8
#
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

User.current = User.system

admin = User.create! name: 'admin', login: 'admin', email: 'admin@om.altimos.de'

Cafeteria.create! name: "Mensa Jena, Ernst-Abbe-Platz", address: "Ernst-Abbe-Platz 8, 07743 Jena, DE",
  user: admin, url: "http://khaos.at/openmensa/jena_eabp.xml"
Cafeteria.create! name: "Mensa Jena, Philosophenweg", address: "Philosophenweg 20, 07743 Jena, DE",
  user: admin, url: "http://khaos.at/openmensa/jena_philweg.xml"
Cafeteria.create! name: "Mensa Jena, Carl-Zeiss-Promenade",  address: "Carl-Zeiss-Promenade 6, 07745 Jena, DE",
  user: admin, url: "http://khaos.at/openmensa/jena_czprom.xml"
Cafeteria.create! name: "Mensa Potsdam, Wildau", address: "Bahnhofstr. 1, 15745 Wildau, DE",
  user: admin, url: "http://www.matthiasspringer.de:5009/wildau.xml"
Cafeteria.create! name: "Mensa Potsdam, Griebnitzsee", address: "August-Bebel-Str. 89, 14482 Potsdam, DE",
  user: admin, url: "http://www.matthiasspringer.de:5009/griebnitzsee.xml"
Cafeteria.create! name: "Mensa Potsdam, Golm", address: "Karl-Liebknecht-Str. 24/25, 14476 Potsdam OT Golm, DE",
  user: admin, url: "http://www.matthiasspringer.de:5009/golm.xml"
Cafeteria.create! name: "Mensa Potsdam, Friedrich-Ebert-Straße", address: "Friedrich-Ebert-Str. 4, 14467 Potsdam, DE",
  user: admin, url: "http://www.matthiasspringer.de:5009/friedrich.xml"
Cafeteria.create! name: "Mensa Potsdam, Pappelallee", address: "Kiepenheuerallee 5, 14469 Potsdam, DE",
  user: admin, url: "http://www.matthiasspringer.de:5009/pappel.xml"
Cafeteria.create! name: "Mensa Potsdam, Brandenburg an der Havel", address: "Magdeburger Straße 50, 14770 Brandenburg an der Havel, DE",
  user: admin, url: "http://www.matthiasspringer.de:5009/brandenburg.xml"
