-- ============================================================
--  Library Management System — PostgreSQL Schema
--  Run this inside: library_db
-- ============================================================

-- ============================================================
-- 1. STAFF (Admins & Librarians — system login users)
-- ============================================================
CREATE TABLE staff (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(100)        NOT NULL,
    email           VARCHAR(255)        NOT NULL UNIQUE,
    password_hash   VARCHAR(255)        NOT NULL,
    role            VARCHAR(20)         NOT NULL CHECK (role IN ('ADMIN', 'LIBRARIAN')),
    is_active       BOOLEAN             NOT NULL DEFAULT TRUE,
    last_login      TIMESTAMP           NULL,
    date_joined     TIMESTAMP           NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 2. MEMBERS (End users who borrow books)
-- ============================================================
CREATE TABLE members (
    id                  SERIAL PRIMARY KEY,
    name                VARCHAR(100)    NOT NULL,
    email               VARCHAR(255)    NOT NULL UNIQUE,
    phone               VARCHAR(20)     NULL,
    address             TEXT            NULL,
    membership_status   VARCHAR(20)     NOT NULL DEFAULT 'ACTIVE'
                            CHECK (membership_status IN ('ACTIVE', 'SUSPENDED', 'EXPIRED')),
    max_borrow_limit    INTEGER         NOT NULL DEFAULT 5,
    total_borrowed      INTEGER         NOT NULL DEFAULT 0,
    date_joined         TIMESTAMP       NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 3. BOOKS
-- ============================================================
CREATE TABLE books (
    id                  SERIAL PRIMARY KEY,
    title               VARCHAR(255)    NOT NULL,
    author              VARCHAR(255)    NOT NULL,
    isbn                VARCHAR(13)     NOT NULL UNIQUE,
    publisher           VARCHAR(255)    NULL,
    page_count          INTEGER         NULL,
    genre               VARCHAR(100)    NULL,
    category            VARCHAR(100)    NULL,
    shelf_location      VARCHAR(50)     NULL,
    total_copies        INTEGER         NOT NULL DEFAULT 1,
    available_copies    INTEGER         NOT NULL DEFAULT 1,
    status              VARCHAR(20)     NOT NULL DEFAULT 'AVAILABLE'
                            CHECK (status IN ('AVAILABLE', 'BORROWED', 'RESERVED', 'LOST')),
    date_added          TIMESTAMP       NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 4. LOANS (Book checkouts)
-- ============================================================
CREATE TABLE loans (
    id              SERIAL PRIMARY KEY,
    member_id       INTEGER         NOT NULL REFERENCES members(id) ON DELETE RESTRICT,
    book_id         INTEGER         NOT NULL REFERENCES books(id)   ON DELETE RESTRICT,
    issued_by_id    INTEGER         NULL     REFERENCES staff(id)   ON DELETE SET NULL,
    issue_date      TIMESTAMP       NOT NULL DEFAULT NOW(),
    due_date        DATE            NOT NULL,
    return_date     DATE            NULL,
    status          VARCHAR(20)     NOT NULL DEFAULT 'ACTIVE'
                        CHECK (status IN ('ACTIVE', 'RETURNED', 'OVERDUE'))
);

-- ============================================================
-- 5. FINES (Generated for overdue loans)
-- ============================================================
CREATE TABLE fines (
    id          SERIAL PRIMARY KEY,
    loan_id     INTEGER         NOT NULL UNIQUE REFERENCES loans(id)   ON DELETE CASCADE,
    member_id   INTEGER         NOT NULL        REFERENCES members(id) ON DELETE RESTRICT,
    amount      NUMERIC(8, 2)   NOT NULL,
    is_paid     BOOLEAN         NOT NULL DEFAULT FALSE,
    paid_date   TIMESTAMP       NULL,
    created_at  TIMESTAMP       NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 6. RESERVATIONS (Queue for unavailable books)
-- ============================================================
CREATE TABLE reservations (
    id              SERIAL PRIMARY KEY,
    member_id       INTEGER         NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    book_id         INTEGER         NOT NULL REFERENCES books(id)   ON DELETE CASCADE,
    reserved_at     TIMESTAMP       NOT NULL DEFAULT NOW(),
    queue_position  INTEGER         NOT NULL,
    status          VARCHAR(20)     NOT NULL DEFAULT 'PENDING'
                        CHECK (status IN ('PENDING', 'FULFILLED', 'CANCELLED')),
    expiry_date     DATE            NULL
);

-- ============================================================
-- INDEXES (for faster queries)
-- ============================================================
CREATE INDEX idx_loans_member_id     ON loans(member_id);
CREATE INDEX idx_loans_book_id       ON loans(book_id);
CREATE INDEX idx_loans_status        ON loans(status);
CREATE INDEX idx_fines_member_id     ON fines(member_id);
CREATE INDEX idx_fines_is_paid       ON fines(is_paid);
CREATE INDEX idx_reservations_book   ON reservations(book_id);
CREATE INDEX idx_reservations_member ON reservations(member_id);
CREATE INDEX idx_books_isbn          ON books(isbn);
CREATE INDEX idx_members_email       ON members(email);

-- ============================================================
-- SAMPLE SEED DATA (optional — for testing)
-- ============================================================

-- Staff
INSERT INTO staff (name, email, password_hash, role) VALUES
  ('Alice Admin',    'alice@library.com',    'hashed_pw_1', 'ADMIN'),
  ('Bob Librarian',  'bob@library.com',      'hashed_pw_2', 'LIBRARIAN');

-- Members
INSERT INTO members (name, email, phone) VALUES
  ('John Doe',   'john@example.com', '0201234567'),
  ('Jane Smith', 'jane@example.com', '0557654321');

-- Books
INSERT INTO books (title, author, isbn, publisher, genre, total_copies, available_copies) VALUES
  ('Clean Code',              'Robert C. Martin', '9780132350884', 'Prentice Hall', 'Technology', 3, 3),
  ('The Pragmatic Programmer','Andrew Hunt',       '9780201616224', 'Addison-Wesley', 'Technology', 2, 2),
  ('Atomic Habits',           'James Clear',       '9780735211292', 'Avery',          'Self-Help',  5, 5);

-- ============================================================
-- VERIFY: List all created tables
-- ============================================================
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
