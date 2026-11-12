// Reverse-geocoding parsing, using REAL Nominatim responses
// (fetched 2026-11-05 from nominatim.openstreetmap.org/reverse?format=jsonv2&addressdetails=1).
import 'dart:convert';

import 'package:ecom_mobile/core/location/geocoder.dart';
import 'package:flutter_test/flutter_test.dart';

/// 11.6040, 104.8830 - Khan Sen Sok, Phnom Penh. Nominatim returns the khan in
/// 'town' and the phum in 'hamlet'; there is NO 'city' key.
const _phnomPenhSenSok = r'''
{
  "place_id": 258754893,
  "licence": "Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright",
  "osm_type": "way",
  "osm_id": 529207693,
  "lat": "11.6046674",
  "lon": "104.8829929",
  "category": "highway",
  "type": "residential",
  "place_rank": 26,
  "importance": 0.053401279468986006,
  "addresstype": "residential",
  "name": "",
  "display_name": "បូរី ប៊ូយុង សែនសុខ, Phum Bonlaa S'et, Khan Sen Sok, Phnom Penh, 120806, Cambodia",
  "address": {
    "residential": "បូរី ប៊ូយុង សែនសុខ",
    "hamlet": "Phum Bonlaa S'et",
    "town": "Khan Sen Sok",
    "state": "Phnom Penh",
    "ISO3166-2-lvl4": "KH-12",
    "postcode": "120806",
    "country": "Cambodia",
    "country_code": "kh"
  },
  "boundingbox": [
    "11.6045979",
    "11.6060641",
    "104.8802137",
    "104.8868072"
  ]
}
''';

/// 11.5700, 104.9100 - Khan Daun Penh, Phnom Penh (khan in 'town', sangkat in 'village').
const _phnomPenhDaunPenh = r'''
{
  "place_id": 258123510,
  "licence": "Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright",
  "osm_type": "way",
  "osm_id": 182123432,
  "lat": "11.5699877",
  "lon": "104.9091531",
  "category": "office",
  "type": "government",
  "place_rank": 30,
  "importance": 6.794613565265915e-05,
  "addresstype": "office",
  "name": "Ministry of National Defense",
  "display_name": "Ministry of National Defense, Bulgaria Boulevard (Street 114), Sangkat Phsar Thmey Ti Pir, Khan Daun Penh, Phnom Penh, 120202, Cambodia",
  "address": {
    "office": "Ministry of National Defense",
    "road": "Bulgaria Boulevard (Street 114)",
    "village": "Sangkat Phsar Thmey Ti Pir",
    "town": "Khan Daun Penh",
    "state": "Phnom Penh",
    "ISO3166-2-lvl4": "KH-12",
    "postcode": "120202",
    "country": "Cambodia",
    "country_code": "kh"
  },
  "boundingbox": [
    "11.5697376",
    "11.5702255",
    "104.9082510",
    "104.9100565"
  ]
}
''';

/// 13.3622, 103.8597 - Siem Reap (a province: 'city', 'county' and 'state').
const _siemReap = r'''
{
  "place_id": 257820496,
  "licence": "Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright",
  "osm_type": "way",
  "osm_id": 701294759,
  "lat": "13.3621583",
  "lon": "103.8599894",
  "category": "highway",
  "type": "primary",
  "place_rank": 26,
  "importance": 0.05338897917143508,
  "addresstype": "primary",
  "name": "Preah Sihanouk Avenue",
  "display_name": "Preah Sihanouk Avenue, Siem Reap, 171201, Cambodia",
  "address": {
    "road": "Preah Sihanouk Avenue",
    "city": "Siem Reap",
    "county": "Siem Reap",
    "state": "Siem Reap",
    "ISO3166-2-lvl4": "KH-17",
    "postcode": "171201",
    "country": "Cambodia",
    "country_code": "kh"
  },
  "boundingbox": [
    "13.3619852",
    "13.3638053",
    "103.8599644",
    "103.8602265"
  ]
}
''';

GeocodeResult? _parse(String raw) => NominatimGeocoder.parse(jsonDecode(raw));

void main() {
  group('City = address.city ?? state ?? province', () {
    test('Phnom Penh (Khan Sen Sok): city is "Phnom Penh", never the khan', () {
      final g = _parse(_phnomPenhSenSok)!;
      expect(g.city, 'Phnom Penh');
      expect(g.city, isNot(contains('Khan')));
      // The khan and phum go into the address line (smallest area first).
      expect(g.line1, "Phum Bonlaa S'et, Khan Sen Sok");
    });

    test('Phnom Penh (Khan Daun Penh): street, sangkat, khan in the line', () {
      final g = _parse(_phnomPenhDaunPenh)!;
      expect(g.city, 'Phnom Penh');
      expect(
        g.line1,
        'Bulgaria Boulevard (Street 114), Sangkat Phsar Thmey Ti Pir, Khan Daun Penh',
      );
    });

    test('Siem Reap (province): city "Siem Reap", line is just the street', () {
      final g = _parse(_siemReap)!;
      expect(g.city, 'Siem Reap');
      // city == county == state: not repeated in the address line.
      expect(g.line1, 'Preah Sihanouk Avenue');
    });

    test('precedence: city, then state, then province', () {
      GeocodeResult? p(Map<String, String> a) =>
          NominatimGeocoder.parse({'address': a});
      expect(p({'city': 'A', 'state': 'B', 'province': 'C'})?.city, 'A');
      expect(p({'state': 'B', 'province': 'C'})?.city, 'B');
      expect(p({'province': 'C'})?.city, 'C');
      // town / district / county are NOT the city.
      expect(
        p({'town': 'Khan Sen Sok', 'state': 'Phnom Penh'})?.city,
        'Phnom Penh',
      );
      expect(p({'county': 'X', 'town': 'Y'})?.city, isNull);
    });
  });

  group('Address line', () {
    test('phum, sangkat and khan are joined smallest area first', () {
      final g = NominatimGeocoder.parse({
        'address': {
          'hamlet': 'Phum Tomnob',
          'village': 'Sangkat Phnom Penh Thmei',
          'town': 'Khan Sen Sok',
          'state': 'Phnom Penh',
        },
      })!;
      expect(g.line1, 'Phum Tomnob, Sangkat Phnom Penh Thmei, Khan Sen Sok');
      expect(g.city, 'Phnom Penh');
    });

    test('house number, street, suburb and district, without duplicates', () {
      final g = NominatimGeocoder.parse({
        'address': {
          'house_number': '5',
          'road': 'Street 63',
          'suburb': 'Boeung Keng Kang 1',
          'city_district': 'Khan Chamkar Mon',
          'district': 'khan chamkar mon', // same value, other key
          'city': 'Phnom Penh',
        },
      })!;
      expect(g.line1, '5 Street 63, Boeung Keng Kang 1, Khan Chamkar Mon');
    });

    test('nothing usable: display_name fallback, then null', () {
      final g = NominatimGeocoder.parse({
        'display_name': 'Wat Phnom, Daun Penh, Phnom Penh, Cambodia',
        'address': {'state': 'Phnom Penh'},
      })!;
      expect(g.line1, 'Wat Phnom, Daun Penh, Phnom Penh');
      expect(NominatimGeocoder.parse({'error': 'Unable to geocode'}), isNull);
      expect(NominatimGeocoder.parse(<String, Object>{}), isNull);
    });
  });
}
