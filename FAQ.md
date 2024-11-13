# Frequently Asked Questions

## How do I create a banner to promote my OpenStreetMap event?

We occasionally display banner images on the main page of [openstreetmap.org](https://www.openstreetmap.org/) to
promote a large OpenStreetMap focused conference or host a worldwide donation
drive.  This is a great way to reach a lot of people!

1. Please review the Operations Working Group's [Banner Policy](https://operations.osmfoundation.org/policies/banner/) to know whether your event qualifies for a front-page banner.
2. Create the banner image.  The image needs to:
   * be exactly 350px wide and at most 350px tall,
   * be in PNG format,
   * have nothing important in the top-right 60x60px corner of the banner which has a close 'X' button overlayed, and
   * have sufficient visual contrast with the colours #cccccc and #999999 so the 'X' can be seen.
3. Prepare a pull request which includes the following:
   * The banner should be saved under the [`app/assets/images/banners/`](https://github.com/openstreetmap/openstreetmap-website/tree/master/app/assets/images/banners) folder, and should have a name that makes it clear what it is for (e.g. `donate-2017.jpg`)
   * Edit [`config/banners.yml`](https://github.com/openstreetmap/openstreetmap-website/blob/master/config/banners.yml) to contain an entry for the event banner.  It should contain the following:
     * `id` - a unique identifier (e.g. `donate2017`)
     * `alt` - alt name for the image (e.g. `OpenStreetMap Funding Drive 2017`)
     * `link` - URL for your event page (e.g. `https://supporting.openstreetmap.org/`)
     * `img` - the filename for the banner image (e.g. `banners/donate-2017.jpg`)
     * `enddate` - the final date that the banner will be shown (e.g. `2017-oct-31`)
   * (optional) Feel free to cleanup the old images from the `app/assets/images/banners/` folder and old entries in the `config/banners.yml` file.
4. The pull request must indicate when the banner should start being shown, which must be at least 7 days after the pull request was created.

See [PR #1296](https://github.com/openstreetmap/openstreetmap-website/pull/1296)
as an example.

## Why don't you assign issues?

We don't assign issues to volunteers for several reasons. The main reasons are that it discourages other volunteers from working on the issue, and the process turns into an unproductive administrative overhead for our team.

There's no need to ask for an issue to be assigned before anyone starts working on it. Everyone is welcome to work on any issue at any time.

In our experience, most people who ask for an issue to be assigned to them never create a pull request. So we would need to keep track of the assigned issues, and remember to unassign them a week or two into the future, when it is likely that they will not be making a PR. Assigned developers might feel bad if they perceive that we're unhappy with their progress, further discouraging them from contributing. Or we will get drawn into discussions about needing more time, or re-assigning them again, or so on. So it is best not to assign in the first place.

The risk that two people are both genuinely working on the same task in the same hour or two is vanishingly remote, and doesn't outweigh the downsides described above. A better approach is to encourage people to simply work on the task and create a pull request, at which point everyone knows that they are actually working on the issue and not just planning/hoping/wishing to do so.
