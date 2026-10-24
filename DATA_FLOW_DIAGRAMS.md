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

    P3 -->|"Read slot details"| DS3
    DS3 -->|"Slot details"| P3

    P3 <-->|"Create / Read / Update appointment"| DS4

    P3 -->|"Booking / Cancellation status"| P
    P3 -->|"Assigned appointment details"| D

```
## 2. Sequence Diagram - Booking an Appointment

```mermaid


sequenceDiagram
    actor Patient
    participant FE as React Frontend
    participant API as Node.js/Express API
    participant DB as PostgreSQL Database

    Patient->>FE: Select doctor and available slot
    FE->>API: POST /appointments (slot_id, reason)
    API->>API: Authenticate user and validate request

    alt Invalid request or unauthorized user
        API-->>FE: 400 Bad Request / 401 Unauthorized
        FE-->>Patient: Display validation or authentication error
    else Valid request
        API->>DB: Begin transaction
        API->>DB: Check slot and insert appointment
        Note over API,DB: Enforce one active appointment per slot
        alt Booking successful
            DB-->>API: Appointment created
            API->>DB: Commit transaction
            API-->>FE: 201 Created
            FE-->>Patient: Display booking confirmation
        else Slot already booked
            DB-->>API: Unique constraint conflict
            API->>DB: Rollback transaction
            API-->>FE: 409 Conflict
            FE-->>Patient: Display slot unavailable message
        else Unexpected database or server error
            DB-->>API: Error
            API->>DB: Rollback transaction
            API-->>FE: 500 Internal Server Error
            FE-->>Patient: Display generic error message
        end
    end


```
## 3. User Flow (Flowchart)

```mermaid


flowchart TD
    Start([Start]) --> Login[User Enters Login Credentials]
    Login --> Auth{Login Successful?}

    Auth -->|No| LoginError[Display Login Error]
    LoginError --> Login

    Auth -->|Yes| RoleCheck{User Role?}

    RoleCheck -->|Patient| PatientHome[Patient Dashboard]
    RoleCheck -->|Doctor| DoctorHome[Doctor Dashboard]

    PatientHome --> Action{Choose Action}

    Action -->|Browse Doctors| Search[Search Doctors and Specialties]
    Search --> ViewSlots[View Doctor Availability Slots]
    ViewSlots --> SelectSlot[Select Desired Slot]
    SelectSlot --> BookReq[Submit Booking Request]
    BookReq --> CheckSlot{Slot Still Available?}

    CheckSlot -->|No| ErrorMsg[Display Slot Unavailable Error]
    ErrorMsg --> ViewSlots

    CheckSlot -->|Yes| SaveDB[Save Appointment in Database]
    SaveDB --> SaveSuccess{Booking Saved Successfully?}
    SaveSuccess -->|Yes| Confirm[Show Booking Success]
    SaveSuccess -->|No| BookingError[Display Booking Failure]
    Confirm --> End([End])
    BookingError --> End

    Action -->|Manage Appointments| ViewApp[View Current Appointments]
    ViewApp --> CancelChoice{Want to Cancel?}

    CancelChoice -->|Yes| CancelDB[Update Appointment Status to Cancelled]
    CancelDB --> CancelSuccess{Cancellation Successful?}
    CancelSuccess -->|Yes| CancelConfirm[Show Cancellation Success]
    CancelSuccess -->|No| CancelError[Display Cancellation Failure]
    CancelConfirm --> End
    CancelError --> End

    CancelChoice -->|No| End

    DoctorHome --> DocView[View Assigned Appointments]
    DocView --> End


```

## 4. Appointment State Diagram

```mermaid

stateDiagram-v2
    [*] --> Booked: Patient books an available slot (UC-02)

    Booked --> PendingConsultation: Consultation time approaches
    Booked --> Cancelled: Patient cancels appointment (UC-08)

    PendingConsultation --> Completed: Consultation session finishes

    Cancelled --> [*]
    Completed --> [*]

```

## 5. Class Diagram

```mermaid

classDiagram
    class User {
        +BigInt user_id PK
        +Varchar email UK
        +Varchar password_hash
        +Varchar role
        +Varchar first_name
        +Varchar last_name
        +Varchar phone
        +Boolean is_active
        +Timestamptz created_at
        +Timestamptz updated_at
        +login()
        +logout()
    }

    class Patient {
        +BigInt patient_id PK
        +BigInt user_id FK_UK
        +Date date_of_birth
        +Varchar gender
        +bookAppointment()
        +cancelAppointment()
    }

    class Doctor {
        +BigInt doctor_id PK
        +BigInt user_id FK_UK
        +Varchar license_number UK
        +Text bio
        +SmallInt years_of_experience
        +viewAssignedAppointments()
    }

    class Specialty {
        +Int specialty_id PK
        +Varchar name UK
        +Text description
    }

    class DoctorSpecialty {
        +BigInt doctor_id PK_FK
        +Int specialty_id PK_FK
    }

    class AvailabilitySlot {
        +BigInt slot_id PK
        +BigInt doctor_id FK
        +Timestamptz start_time
        +Timestamptz end_time
        +Timestamptz created_at
    }

    class Appointment {
        +BigInt appointment_id PK
        +BigInt patient_id FK
        +BigInt slot_id FK
        +Varchar status
        +Varchar reason
        +Timestamptz cancelled_at
        +Timestamptz created_at
        +Timestamptz updated_at
        +create()
        +cancel()
    }

    User "1" --> "0..1" Patient : profile
    User "1" --> "0..1" Doctor : profile

    Doctor "1" --> "1..*" DoctorSpecialty : specialties
    Specialty "1" --> "0..*" DoctorSpecialty : doctors

    Doctor "1" --> "0..*" AvailabilitySlot : publishes
    Patient "1" --> "0..*" Appointment : books
    AvailabilitySlot "1" --> "0..*" Appointment : appointment history

```
