test_that("oe_update(): simplest example works", {
  skip_if_offline()
  out = oe_get(
    "ITS Leeds",
    provider = "test",
    download_directory = tempdir(),
    download_only = TRUE,
    quiet = TRUE
  )
  expect_error(oe_update(tempdir(), quiet = TRUE), NA)
  # AG: I decided to comment out that test since I don't see any benefit testing
  # the "verbose" output during R CMD checks (that I rarely check manually)
  # expect_message(oe_update(fake_dir, quiet = FALSE))

  file.remove(oe_find("ITS Leeds", download_directory = tempdir()))
})
