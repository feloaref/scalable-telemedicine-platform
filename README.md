# Scalable Telemedicine Platform

A scalable telemedicine platform project focused on applying modern DevOps practices, cloud infrastructure, automation, security, and monitoring to a web application.

This platform enables patients to search for doctors, book appointments, and manage their consultations online. It is built using modern web technologies and designed to support future scalability and cloud deployment.

---

## Project Overview

The project aims to develop and deploy a web-based telemedicine application using a modern technology stack and a planned DevOps toolchain.

The application provides patient and doctor functionality, including registration, authentication, doctor discovery, appointment booking, and appointment management.

The DevOps part focuses on containerization, CI/CD, infrastructure automation, deployment, security, monitoring, and logging.

## Project Objectives

- Establish a documented and maintainable application deployment workflow.
- Automate build and validation tasks through CI/CD.
- Package application components using containers.
- Prepare scalable deployment infrastructure.
- Apply security and code-quality checks.
- Monitor application health, metrics, and logs.

## Initial Project Scope

The proposed Minimum Viable Product (MVP) includes:

- Patient and doctor user roles.
- User registration and login.
- Doctor profiles and specialties.
- Appointment booking, viewing, and cancellation.
- Persistent application data storage.

Real-time video consultations, online payments, and real patient medical records are outside the initial MVP scope.

---

## Features

### For Patients

- User registration and authentication.
- Search doctors by specialty.
- View doctor profiles with details.
- Browse available appointment slots.
- Book appointments with a reason for visit.
- View upcoming and past appointments.
- Cancel appointments.

### For Doctors

- User registration with license information.
- Manage availability slots.
- View assigned appointments.
- Update appointment statuses.
- Track consultation history.

### System Features

- Prevention of appointment double-booking.
- Database-level referential integrity.
- Role-based access control (Patient/Doctor/Admin).
- Secure password hashing using PBKDF2.
- BigInt support for database identifiers.
- RESTful APIs with error handling.
- HTTP-only authentication cookies.
- Server-side input validation.

---

## Architecture

### Database Schema

The application uses a relational database structure:

```text
Users (Patients, Doctors, Admins)
 ├── Patients (1:1 with Users)
 │    └── Appointments (1:N)
 │         └── Availability Slots
 ├── Doctors (1:1 with Users)
 │    ├── Specialties (N:N)
 │    └── Availability Slots (1:N)
 └── Specialties
```

### Application Technology Stack

- **Frontend:** Next.js 16, React 19, Tailwind CSS
- **Backend:** Next.js API Routes
- **Database:** PostgreSQL
- **ORM:** Drizzle ORM
- **Authentication:** JWT with HTTP-only cookies
- **Password Security:** PBKDF2 hashing
- **Version Control:** Git and GitHub

### Planned DevOps Technology Stack

#### Application and Infrastructure

- React
- Node.js
- PostgreSQL
- Redis

#### DevOps and Infrastructure

- Git and GitHub
- Jenkins
- Docker and Docker Compose
- Ansible
- Kubernetes
- Nginx
- Terraform
- AWS

#### Security and Code Quality

- SonarQube
- Trivy

#### Monitoring and Logging

- Prometheus
- Grafana
- Loki

The listed technologies represent the proposed DevOps stack. Their final use will be confirmed during implementation.

---

## Team Responsibilities

| Team Member | Assigned Tools |
|---|---|
| Ziad | Docker and Ansible |
| Felopateer | Kubernetes and Nginx |
| Hisham | Jenkins and Git |
| Mohamed | Terraform and AWS |
| Omar | Prometheus and Grafana |

Team members will coordinate during integration, troubleshooting, testing, and documentation.

---

## Project Planning

Project planning activities are tracked through GitHub Issues and the GitHub Projects board.

The planning activities cover:

1. Project scope and requirements.
2. System architecture.
3. Team roles and responsibilities.
4. Project timeline and milestones.
5. Git workflow and branch strategy.
6. Technology stack documentation.
7. Risk assessment and mitigation.
8. Project KPIs and evaluation planning.

### System Architecture

The proposed architecture and its discussion are documented in the [System Architecture Issue](https://github.com/feloaref/scalable-telemedicine-platform/issues/2).

---

## Installation & Setup

### Prerequisites

- Node.js 18+
- PostgreSQL 13+
- npm or yarn

### 1. Clone the Repository

```bash
git clone https://github.com/feloaref/scalable-telemedicine-platform.git
cd scalable-telemedicine-platform
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Environment Configuration

Create a `.env` file in the project root and configure the required environment variables.

```env
DATABASE_URL=postgresql://USER:PASSWORD@127.0.0.1:5432/app_db
JWT_SECRET=your-secure-random-secret
NODE_ENV=development
SEED_SECRET=your-local-seed-secret
```

Replace the example values with your own local configuration. Never commit `.env` or expose its secrets.

### 4. Database Setup

Apply the database migrations:

```bash
npx drizzle-kit migrate
```

### 5. Run the Development Server

```bash
npm run dev
```

Visit:

```text
http://localhost:3000
```

---

## Run with Docker

Node.js and PostgreSQL are not required, only Docker with the compose plugin.

```bash
cp .env.example .env    # then replace every "change-this" value
docker compose up --build -d
```

Open `http://localhost:3000`. For demo data, environment variables, Ansible deployment and notes for Jenkins, Kubernetes and Nginx, see [DOCKER_ANSIBLE.md](DOCKER_ANSIBLE.md).

---

## API Documentation

### Authentication

#### Register

```http
POST /api/auth/register
Content-Type: application/json
```

Example request:

```json
{
  "email": "newuser@example.com",
  "password": "securepassword123",
  "confirmPassword": "securepassword123",
  "role": "patient",
  "firstName": "John",
  "lastName": "Doe",
  "phone": "+1234567890",
  "dateOfBirth": "1990-01-01",
  "gender": "Male"
}
```

#### Login

```http
POST /api/auth/login
Content-Type: application/json
```

Example request:

```json
{
  "email": "patient@example.com",
  "password": "your-password"
}
```

Successful authentication sets an HTTP-only authentication cookie.

### Doctors

#### Get All Doctors

```http
GET /api/doctors
```

#### Filter by Specialty

```http
GET /api/doctors?specialtyId=1
```

#### Search by Name

```http
GET /api/doctors?search=Sarah
```

#### Get Doctor Details

```http
GET /api/doctors/{doctorId}
```

#### Get Doctor Availability

```http
GET /api/doctors/{doctorId}/slots
```

### Specialties

#### Get All Specialties

```http
GET /api/specialties
```

#### Create Specialty (Admin)

```http
POST /api/specialties
Content-Type: application/json
```

Example request:

```json
{
  "name": "Psychiatry",
  "description": "Mental health and counseling"
}
```

This endpoint requires administrator authorization.

### Appointments

#### Book Appointment

```http
POST /api/appointments
Content-Type: application/json
```

Example request:

```json
{
  "slotId": "25",
  "reason": "Regular checkup and consultation"
}
```

The patient identity is obtained from the authenticated user session rather than trusting a patient ID supplied by the client.

#### Get Patient Appointments

```http
GET /api/appointments
```

The API returns appointments belonging to the authenticated patient.

#### Cancel Appointment

```http
POST /api/appointments/{appointmentId}/cancel
```

Only the appointment owner can cancel their appointment.

### Doctor Appointments

Doctors can retrieve their assigned appointments and update appointment statuses through the doctor appointment API endpoints.

---

## Pages & Routes

### Patient Routes

| Route | Description |
|---|---|
| `/` | Home page |
| `/register?role=patient` | Patient registration |
| `/login` | Login page |
| `/patient/dashboard` | Patient dashboard |
| `/patient/search` | Find doctors |
| `/patient/doctor/[id]` | Doctor profile and booking |
| `/patient/appointments` | Patient appointments |

### Doctor Routes

| Route | Description |
|---|---|
| `/register?role=doctor` | Doctor registration |
| `/doctor/dashboard` | Doctor dashboard |
| `/doctor/appointments` | Doctor appointments |
| `/doctor/availability` | Manage availability slots |

---

## Security Features

- **Password Hashing:** PBKDF2 with salt.
- **Authentication:** JWT-based authentication using HTTP-only cookies.
- **Role-Based Access:** Patient, Doctor, and Admin roles.
- **Appointment Ownership:** Users can access only their authorized appointments.
- **Double-Booking Prevention:** Database constraints and transaction-based booking.
- **Referential Integrity:** Foreign keys and database constraints.
- **Input Validation:** Server-side validation for API requests.
- **Environment Protection:** Sensitive configuration stored in environment variables.

---

## Database Performance

The database uses relational constraints and indexes to support data integrity and efficient queries.

Important areas include:

- Doctor availability lookup.
- Appointment lookup by patient.
- Appointment status filtering.
- Unique appointment slot booking constraints.
- Foreign-key relationships between users, doctors, patients, and appointments.

---

## Testing

### Patient Flow

1. Register as a patient.
2. Log in.
3. Browse doctors by specialty.
4. View doctor availability.
5. Book an appointment.
6. View appointments.
7. Cancel an appointment.

### Doctor Flow

1. Register as a doctor.
2. Log in to the doctor dashboard.
3. Manage availability