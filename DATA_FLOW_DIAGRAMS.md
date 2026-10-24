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

```mermaid
sequenceDiagram
    autonumber
    actor Patient
    participant FE as React Frontend
    participant BE as Node.js / Express API
    participant DB as PostgreSQL Database

    Patient->>FE: Browse doctors and available slots
    FE->>BE: GET /api/doctors/{id}/slots
    BE->>DB: Query available slots
    DB-->>BE: Return available slots
    BE-->>FE: 200 OK - Slots list
    FE-->>Patient: Display available slots

    Patient->>FE: Select slot and submit booking
    FE->>BE: POST /api/appointments
    Note over FE,BE: Request includes slot_id and booking details

    BE->>BE: Validate request and user permissions
    BE->>DB: Attempt atomic booking

    alt Booking succeeds
        DB-->>BE: Appointment saved
        BE-->>FE: 201 Created - Booking confirmed
        FE-->>Patient: Display booking confirmation
    else Slot already booked
        DB-->>BE: Unique constraint conflict
        BE-->>FE: 409 Conflict - Slot unavailable
        FE-->>Patient: Show error and request another slot
    else Unexpected server or database error
        DB-->>BE: Operation failed
        BE-->>FE: 500 Internal Server Error
        FE-->>Patient: Display failure message
    end
```
## 2. Sequence Diagram - Booking an Appointment

```mermaid
sequenceDiagram
    autonumber
    actor Patient as Patient
    participant FE as React Frontend
    participant BE as Node.js / Express API
    participant DB as PostgreSQL Database

    Patient->>FE: Browse doctors and view available slots
    FE->>BE: GET /api/doctors/{id}/slots
    BE->>DB: Query available slots
    DB-->>BE: Return available slots
    BE-->>FE: Return slots list
    FE-->>Patient: Display available time slots

    Patient->>FE: Select slot and submit booking request
    FE->>BE: POST /api/appointments
    BE->>DB: Validate slot and attempt booking

    alt Booking succeeds
        DB-->>BE: Appointment saved successfully
        BE-->>FE: 201 Created - Booking Confirmed
        FE-->>Patient: Display booking confirmation
    else Slot is no longer available
        DB-->>BE: Booking rejected due to slot conflict
        BE-->>FE: 409 Conflict - Slot Unavailable
        FE-->>Patient: Display error and request another slot
    else Database operation fails
        DB-->>BE: Database operation failed
        BE-->>FE: 500 Internal Server Error
        FE-->>Patient: Display booking failure message
    end
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
