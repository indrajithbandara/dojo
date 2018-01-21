package calculator

import (
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
    "testing"
)

type randomMock struct {
    mock.Mock
}

func (o randomMock) Random(limit int) int {
    args := o.Called(limit)
    return args.Int(0)
}

func TestAdd(t *testing.T) {
    calc := newCalculator(nil)
    assert.Equal(t, 9, calc.Add(5, 4))
}

func TestSubtract(t *testing.T) {
    calc := newCalculator(nil)
    assert.Equal(t, 1, calc.Subtract(5, 4))
}

func TestMultiply(t *testing.T) {
    calc := newCalculator(nil)
    assert.Equal(t, 20, calc.Multiply(5, 4))
}

func TestDivide(t *testing.T) {
    calc := newCalculator(nil)
    assert.Equal(t, 4, calc.Divide(20, 4))
}

func TestRandom(t *testing.T) {
    rnd := new(randomMock)
    rnd.On("Random", 100).Return(7)
    calc := newCalculator(rnd)
    assert.Equal(t, 7, calc.Random())
}

