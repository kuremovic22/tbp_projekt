# Upute za pokretanje aplikacije

Projekt je razvijen i testiran na Ubuntu Linux virtualnoj mašini s lokalno instaliranim PostgreSQL i PostGIS ekstenzijom.

## Preduvjeti:
* Ubuntu Linux (preporučeno)
* Python 3.10+
* PostgreSQL 14+ s instaliranim PostGIS ekstenzijom
* Korisnik s sudo pravima (za inicijalizaciju baze)
* Internet veza (opcionalno, za automatski geocoding adresa)

## Struktura projekta:
* app.py – Flask web aplikacija
* scripts/init_db.sh – skripta za automatizirano kreiranje baze podataka
* db/ – SQL skripte (schema, napredni objekti, testni podaci)
* templates/ – HTML predlošci korisničkog sučelja
* requirements.txt – Python ovisnosti
* run.sh – skripta za pokretanje cijelog sustava

## Pokretanje aplikacije:

1. Otvoriti terminal i pozicionirati se u root direktorij projekta.

2. (Opcionalno) Kopirati i prilagoditi konfiguraciju:
    cp .env.example .env


3. Pokrenuti aplikaciju jednom naredbom:

   chmod +x run.sh
   
   ./run.sh


5. Nakon uspješnog pokretanja aplikacija je dostupna na adresi:

    http://127.0.0.1:5000


Skripta run.sh automatski:
*kreira Python virtualno okruženje,
*instalira potrebne ovisnosti,
*inicijalizira bazu podataka pomoću skripte scripts/init_db.sh,
*pokreće Flask web aplikaciju.

## Napomena:

Skripta scripts/init_db.sh koristi sudo -u postgres te pretpostavlja lokalno instaliran PostgreSQL s PostGIS ekstenzijom.
Automatsko određivanje lokacije koristi Nominatim (OpenStreetMap) servis; u slučaju nedostupnosti moguće je ručno unijeti koordinate.
