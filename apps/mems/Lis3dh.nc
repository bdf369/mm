interface Lis3dh {
  command error_t whoAmI(uint8_t *id);
  command error_t config1Hz();
}
