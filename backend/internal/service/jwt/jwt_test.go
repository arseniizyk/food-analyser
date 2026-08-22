package jwt

import (
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

const testSecret = "test-secret"

func TestManager_IssueParse(t *testing.T) {
	m, err := New(testSecret, time.Hour)
	if err != nil {
		t.Fatalf("New: %v", err)
	}

	token, err := m.Issue("user-uuid")
	if err != nil {
		t.Fatalf("Issue: %v", err)
	}

	got, err := m.Parse(token)
	if err != nil {
		t.Fatalf("Parse: %v", err)
	}
	if got != "user-uuid" {
		t.Fatalf("Parse returned %q, want %q", got, "user-uuid")
	}
}

func TestManager_New_EmptySecret(t *testing.T) {
	if _, err := New("", time.Hour); err == nil {
		t.Fatal("New with empty secret: expected error, got nil")
	}
}

func TestManager_Parse_TamperedSignature(t *testing.T) {
	m, err := New(testSecret, time.Hour)
	if err != nil {
		t.Fatalf("New: %v", err)
	}

	token, err := m.Issue("user-uuid")
	if err != nil {
		t.Fatalf("Issue: %v", err)
	}

	tampered := token[:len(token)-4] + "xxxx"
	if _, err := m.Parse(tampered); err == nil {
		t.Fatal("Parse of tampered token: expected error, got nil")
	}
}

func TestManager_Parse_WrongSecret(t *testing.T) {
	m1, err := New(testSecret, time.Hour)
	if err != nil {
		t.Fatalf("New: %v", err)
	}
	m2, err := New("another-secret", time.Hour)
	if err != nil {
		t.Fatalf("New: %v", err)
	}

	token, err := m1.Issue("user-uuid")
	if err != nil {
		t.Fatalf("Issue: %v", err)
	}

	if _, err := m2.Parse(token); err == nil {
		t.Fatal("Parse with wrong secret: expected error, got nil")
	}
}

func TestManager_Parse_Expired(t *testing.T) {
	m, err := New(testSecret, time.Millisecond)
	if err != nil {
		t.Fatalf("New: %v", err)
	}

	token, err := m.Issue("user-uuid")
	if err != nil {
		t.Fatalf("Issue: %v", err)
	}

	time.Sleep(10 * time.Millisecond)

	if _, err := m.Parse(token); err == nil {
		t.Fatal("Parse of expired token: expected error, got nil")
	}
}

func TestManager_Parse_MissingUserID(t *testing.T) {
	m, err := New(testSecret, time.Hour)
	if err != nil {
		t.Fatalf("New: %v", err)
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub": "user-uuid",
		"exp": time.Now().Add(time.Hour).Unix(),
	})
	signed, err := token.SignedString([]byte(testSecret))
	if err != nil {
		t.Fatalf("SignedString: %v", err)
	}

	if _, err := m.Parse(signed); err == nil {
		t.Fatal("Parse of token without user_id claim: expected error, got nil")
	}
}

func TestManager_Parse_RejectsAlgorithmConfusion(t *testing.T) {
	m, err := New(testSecret, time.Hour)
	if err != nil {
		t.Fatalf("New: %v", err)
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS512, jwt.MapClaims{
		"sub":     "user-uuid",
		"user_id": "user-uuid",
		"exp":     time.Now().Add(time.Hour).Unix(),
	})
	signed, err := token.SignedString([]byte(testSecret))
	if err != nil {
		t.Fatalf("SignedString: %v", err)
	}

	if _, err := m.Parse(signed); err == nil {
		t.Fatal("Parse of HS512-signed token: expected error, got nil")
	}
}
