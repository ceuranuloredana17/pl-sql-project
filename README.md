# 🏨 PL/SQL Project – Guesthouse Management Database

This repository contains a **PL/SQL project** for managing the activity of a guesthouse (pensiune).  
It extends the SQL schema with **procedural logic**, including cursors, exceptions, functions, procedures, packages, and triggers.

---

## 📂 Structure
- `exercises.sql` → All PL/SQL blocks (cursors, exceptions, functions, procedures, packages, triggers).  

---

## 🚀 How to Run
1. Open Oracle SQL*Plus or SQL Developer.  
2. Make sure the base schema (tables: `CLIENTI`, `CAMERE`, `REZERVARI`, `PLATI`, etc.) is already created.  
3. Run the script:
   ```sql
   @exercises.sql

   
Enable server output to see messages: 
SET SERVEROUTPUT ON;

🛠️ Topics Covered

Cursors

-Explicit cursors with and without parameters

-Implicit cursors with and without parameters

Exception Handling

-Custom exceptions (e.g., client not found, invalid price)

Functions

-CalculPretTotal – total price per stay

-VerificaClientFidel – checks client loyalty

-GetNumeComplet – returns full name

Procedures

-FinalizeazaRezervare, AnuleazaRezervare, VerificaDisponibilitateCamera1

Packages

-actualizare_clienti (CRUD operations for clients)

-actualizare_camere (CRUD operations for rooms)

Triggers

-Prevent overlapping reservations

-Audit deleted reservations

-Update room status after booking
