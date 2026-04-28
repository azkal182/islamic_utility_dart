enum Madhab {
  shafi,
  hanafi;

  int get shadowLength => this == Madhab.hanafi ? 2 : 1;
}
