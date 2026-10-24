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
    P3 <-->|"Check / Update slot availability"| DS3
    P3 <-->|"Create / Read / Update appointment"| DS4
    P3 -->|"Booking / Cancellation status"| P
    P3 -->|"Assigned appointment details"| D
```
## 2. Sequence Diagram - Booking an Appointment

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
    PendingConsultation --> Cancelled: Cancellation allowed by policy

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
