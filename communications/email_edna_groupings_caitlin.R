# Email to Caitlin re: eDNA sample groupings update
# Uses blastula for email composition and sending

# Build the email
email <- blastula::compose_email(

  body = blastula::md(glue::glue(
    "
Hi Caitlin,

Thanks so much for the wrangle - super helpful!

Good news on the burbot assay - thanks. That's a tasty (and sometimes rare) cod so nice to be able to understand where it likely is and isn't...

I've gone through and made some tweaks based on your feedback:

- Subbed BT in for PK on that one sample (197960_ds_ed1) so it slides into Group 8 now - that group has 10 samples with the addition.
- Swapped KO to SK throughout since it's the same SOCK assay

One thing that popped up - site **197379_us_ed1** has a combo (BT CO RB) that wasn't in your 13 groups. I've stuck it in a new Group 14 for now...

I matched the run order and sheet naming to what you had in the Excel you sent back. The ordering is driven by [this CSV](https://github.com/NewGraphEnvironment/dff-2022/blob/main/data/edna_group_run_order.csv) so if you want any changes to the species order within groups just let me know and we can update it easily.

You can grab the updated files here:

- **CSV:** [edna_species_for_UNBC.csv](https://github.com/NewGraphEnvironment/m1rr0r/blob/main/fish_passage_template_reporting/data/backup/2025/edna_species_for_UNBC.csv)
- **Excel (grouped sheets):** [edna_species_for_UNBC_grouped.xlsx](https://github.com/NewGraphEnvironment/m1rr0r/blob/main/fish_passage_template_reporting/data/backup/2025/edna_species_for_UNBC_grouped.xlsx). Excel files don't render but there is a download button top right.

Also - if you or your teams ever want to poke around or adapt the workflow, the [R scripts](https://github.com/NewGraphEnvironment/dff-2022/tree/main/scripts) and [assay mapping table](https://github.com/NewGraphEnvironment/dff-2022/blob/main/data/edna_assays.csv) are linked if you're interested.

Stoked that you have someone lined up to help out with the lab coat on!

Let me know if anything else needs adjusting on our end.

Thanks again. Really appreciated.

Al

Al Irvine B.Sc., R.P.Bio.<br>
New Graph Environment Ltd.<br>
<br>
Cell: 250-777-1518<br>
Email: al@newgraphenvironment.com<br>
Website: www.newgraphenvironment.com
"
  ))
)

# Preview the email
email

# Send the email
email |>
  blastula::smtp_send(
    from = "al@newgraphenvironment.com",
    cc = "info@newgraphenvironment.com",
    # to = "al@newgraphenvironment.com",


    to = "Caitlin.Pitt@unbc.ca",
    subject = "eDNA - September 2025 - Peace - Fraser - Skeena - UNBC - sample plan",
    credentials = blastula::creds_key(id = "gmail")
  )
