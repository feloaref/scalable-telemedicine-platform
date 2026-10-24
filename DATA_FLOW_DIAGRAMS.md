# Data Flow and System Behavior - Scalable Telemedicine Platform

## 1. Data Flow Diagrams (DFD)

### 1.1. Context-Level DFD (Level 0)

```mermaid
graph TD
    Patient["Patient"] -->|"Registration, Search Doctors, Book/Cancel Appointment"| System(("Scalable Telemedicine Platform"))
    Doctor["Doctor"] -->|"View Assigned Appointments, Manage Profile"| System
    System -->|"Booking Confirmation, Doctor List, Status Updates"| Patient
    System -->|"Appointment Details"| Doctor
```

### 1.2. Level 1 DFD


graph TD
    subgraph ext["External Entities"]
        P["Patient"]
        D["Doctor"]
    end

    subgraph proc["System Processes"]
        P1["1.0 User Authentication"]
        P2["2.0 Doctor Search and Browse"]
        P3["3.0 Appointment Management"]
    end

    subgraph store["Data Stores"]
        DS1[("Users and Profiles DB")]
        DS2[("Doctors and Specialties DB")]
        DS3[("Availability Slots DB")]
        DS4[("Appointments DB")]
    end

    P -->|"Registration / Login credentials"| P1
    D -->|"Login credentials"| P1
    P1 <-->|"Read / Create / Update user data"| DS1
    P1 -->|"Authentication result"| P
    P1 -->|"Authentication result"| D

    P -->|"Search criteria / Specialty"| P2
    P2 -->|"Query doctor profiles and specialties"| DS2
    DS2 -->|"Doctor profiles and specialties"| P2
    P2 -->|"Query available slots"| DS3
    DS3 -->|"Available slots"| P2
    P2 -->|"Doctor list and availability"| P

    P -->|"Book / Cancel appointment request"| P3
    D -->|"View assigned appointments request"| P3
    P3 <-->|"Check / Update slot availability"| DS3
    P3 <-->|"Create / Read / Update appointment"| DS4
    P3 -->|"Booking / Cancellation status"| P
    P3 -->|"Assigned appointment details"| D


## 2. Sequence Diagram - Booking an Appointment

```mermaid
sequenceDiagram
    autonumber
    actor Patient as Patient
    participant FE as React Frontend
    participant BE as Node.js / Express API
    participant DB as PostgreSQL Database

    Patient->>FE: Browse doctors & view available slots
    FE->>BE: GET /api/doctors/{id}/slots
    BE->>DB: Query available availability_slots
    DB-->>BE: Return active slots
    BE-->>FE: Send slots list
    FE-->>Patient: Display available time slots

    Patient->>FE: Select slot & submit booking request
    FE->>BE: POST /api/appointments (patient_id, slot_id, reason)
    BE->>DB: INSERT INTO appointments (patient_id, slot_id, status='booked')
    Note over BE,DB: Database partial unique index ensures<br/>no double-booking for the active slot.
    DB-->>BE: Appointment saved successfully
    BE-->>FE: Return 201 Created (Booking Confirmed)
    FE-->>Patient: Display confirmation message
```

## 3. User Flow (Flowchart)

```mermaid
flowchart TD
    Start([Start]) --> Login[User Logs In]
    Login --> RoleCheck{User Role?}

    RoleCheck -->|Patient| PatientHome[Patient Dashboard]
    RoleCheck -->|Doctor| DoctorHome[Doctor Dashboard]

    PatientHome --> Action{Choose Action}

    Action -->|Browse Doctors| Search[Search Doctors & Specialties]
    Search --> ViewSlots[View Doctor Availability Slots]
    ViewSlots --> SelectSlot[Select Desired Slot]
    SelectSlot --> BookReq[Submit Booking Request]
    BookReq --> CheckSlot{Slot Still Available?}
    CheckSlot -->|No| ErrorMsg["Display 'Slot No Longer Available'"]
    ErrorMsg --> ViewSlots
    CheckSlot -->|Yes| SaveDB[Save Appointment in DB]
    SaveDB --> Confirm[Show Booking Success]

    Action -->|Manage Appointments| ViewApp[View Current Appointments]
    ViewApp --> CancelChoice{Want to Cancel?}
    CancelChoice -->|Yes| CancelDB[Update Appointment Status to Cancelled]
    CancelDB --> CancelConfirm[Show Cancellation Success]
    CancelChoice -->|No| End([End])

    DoctorHome --> DocView[View Assigned Appointments]
    DocView --> End

    Confirm --> End
    CancelConfirm --> End
```

## 4. Appointment State Diagram

```mermaid
stateDiagram-v2
    [*] --> Booked : Patient books an available slot (UC-02)

    state Booked {
        [*] --> Active
        Active --> PendingConsultation : Time approaches
    }

    Booked --> Cancelled : Patient cancels appointment (UC-08)
    Booked --> Completed : Consultation session finishes

    Cancelled --> [*]
    Completed --> [*]
```

## 5. Class Diagram

```mermaid
classDiagram
    class User {
        +BigInt user_id
        +Varchar email
        +Varchar password_hash
        +Varchar role
        +Varchar first_name
        +Varchar last_name
        +Varchar phone
        +Boolean is_active
        +Timestamp created_at
        +login()
        +logout()
    }

    class Patient {
        +BigInt patient_id
        +BigInt user_id
        +Date date_of_birth
        +Varchar gender
        +bookAppointment()
        +cancelAppointment()
    }

    class Doctor {
        +BigInt doctor_id
        +BigInt user_id
        +Varchar license_number
        +Text bio
        +SmallInt years_of_experience
        +viewAssignedAppointments()
    }

    class Specialty {
        +Int specialty_id
        +Varchar name
        +Text description
    }

    class AvailabilitySlot {
        +BigInt slot_id
        +BigInt doctor_id
        +Timestamp start_time
        +Timestamp end_time
    }

    class Appointment {
        +BigInt appointment_id
        +BigInt patient_id
        +BigInt slot_id
        +Varchar status
        +Varchar reason
        +Timestamp cancelled_at
        +create()
        +cancel()
    }

    User "1" --> "0..1" Patient : profile
    User "1" --> "0..1" Doctor : profile
    Doctor "1" --> "*" AvailabilitySlot : publishes
    Doctor "*" --> "*" Specialty : practices
    Patient "1" --> "*" Appointment : books
    AvailabilitySlot "1" --> "0..1" Appointment : reserved_by
```
