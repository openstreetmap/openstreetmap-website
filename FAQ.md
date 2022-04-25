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
     * `link` - URL for your event page (e.g. `https://donate.openstreetmap.org/`)
     * `img` - the filename for the banner image (e.g. `banners/donate-2017.jpg`)
     * `enddate` - the final date that the banner will be shown (e.g. `2017-oct-31`)
   * (optional) Feel free to cleanup the old images from the `app/assets/images/banners/` folder and old entries in the `config/banners.yml` file.
4. The pull request must indicate when the banner should start being shown, which must be at least 7 days after the pull request was created.

See [PR #1296](https://github.com/openstreetmap/openstreetmap-website/pull/1296)
as an example.
