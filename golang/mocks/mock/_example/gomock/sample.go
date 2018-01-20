package sample

type Sample interface {
    Method(s string) int
}

type writer interface {
    Write([]byte) (int, error)
}

