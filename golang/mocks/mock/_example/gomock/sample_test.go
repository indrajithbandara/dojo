package sample

import (
    "testing"
    "github.com/golang/mock/gomock"
    mock "./mock_sample"

    "fmt"
)

func TestSample00(t *testing.T) {
    // single test cases
    ctrl := gomock.NewController(t)
    defer ctrl.Finish()
    mockSample := mock.NewMockSample(ctrl)

    // Method() should be called with "foo"
    mockSample.EXPECT().Method("foo")
    // mockSample.EXPECT().Method("hoge").Return(1)

    t.Log("result:", mockSample.Method("foo"))
}

func TestSample01(t *testing.T) {
    // single test cases
    ctrl := gomock.NewController(t)
    defer ctrl.Finish()
    mockSample := mock.NewMockSample(ctrl)

    // Method() should be called with "foo" then "bar"
    mockSample.EXPECT().Method("foo")
    mockSample.EXPECT().Method("bar")

    t.Log("result:", mockSample.Method("foo"))
    t.Log("result:", mockSample.Method("bar"))
}

func TestSample02(t *testing.T) {
    // single test cases
    ctrl := gomock.NewController(t)
    defer ctrl.Finish()
    mockSample := mock.NewMockSample(ctrl)

    // Method() should be called with "foo" then "bar"
    mockSample.EXPECT().Method("foo").Times(2)

    t.Log("result:", mockSample.Method("foo"))
    t.Log("result:", mockSample.Method("foo"))
}

func TestSample03(t *testing.T) {
    ctrl := gomock.NewController(t)
    defer ctrl.Finish()

    w := mock.NewMockwriter(ctrl)

    gomock.InOrder(
        w.EXPECT().Write([]byte("foo")).Return(4, nil),
        w.EXPECT().Write([]byte("bar")).Return(4, nil),
    )
    fmt.Fprintf(w, "foo")
    fmt.Fprintf(w, "bar")
}

