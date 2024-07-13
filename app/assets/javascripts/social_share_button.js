// Opening pop-ups with share url
function openShareUrl(url, initialWidth = 640, initialHeight = 480) {
  if (typeof url !== "string" || !url.startsWith("http")) {
    console.error("Invalid URL");
    return;
  }

  const width = Math.max(100, Math.min(screen.width, initialWidth));
  const height = Math.max(100, Math.min(screen.height, initialHeight));

  const left = (screen.width / 2) - (width / 2);
  const top = (screen.height * 0.3) - (height / 2);
  const opts = `width=${width},height=${height},left=${left},top=${top},menubar=no,status=no,location=no`;

  const newWindow = window.open(url, "popup", opts);

  if (!newWindow || newWindow.closed || typeof newWindow.closed == "undefined") {
    console.error("Popup blocked. Please allow popups for this website.");
  }
}


// Generates share URLs for various social media platforms based on the provided platform key and parameters
const shareUrlGenerators = {
  email: ({ title, url }) => `mailto:?subject=${encodeURIComponent(title)}&body=${encodeURIComponent(url)}`,
  twitter: ({ title, url, via, hashtags }) => {
    const via_str = via ? `&via=${encodeURIComponent(via)}` : "";
    const hashtags_str = hashtags ? `&hashtags=${encodeURIComponent(hashtags.join(","))}` : "";
    return `https://twitter.com/intent/tweet?url=${encodeURIComponent(url)}&text=${encodeURIComponent(title)}${hashtags_str}${via_str}`;
  },
  linkedin: ({ url }) => `https://www.linkedin.com/shareArticle?mini=true&url=${encodeURIComponent(url)}`,
  facebook: ({ url }) => `https://www.facebook.com/sharer/sharer.php?url=${encodeURIComponent(url)}`,
  mastodon: ({ title, url }) => `https://mastodon.social/share?text=${encodeURIComponent(title)}&url=${encodeURIComponent(url)}`,
  telegram: ({ title, url }) => `https://t.me/share/url?url=${encodeURIComponent(url)}&text=${encodeURIComponent(title)}`
};

// Handles social share button clicks by generating and opening the appropriate share URL based on data attributes.
$(document).on("click", ".social-share-button .ssb-icon", function (e) {
  e.preventDefault();

  const $parent = $(this).closest(".social-share-button");
  const site = $(this).data("site");
  const shareData = {
    title: $parent.data("title") || "",
    img: $parent.data("img") || "",
    url: $parent.data("url") || location.href,
    via: $parent.data("via") || "",
    desc: $parent.data("desc") || "",
    hashtags: $parent.data("hashtags") || ""
  };

  const shareUrl = shareUrlGenerators[site] ? shareUrlGenerators[site](shareData) : null;

  if (shareUrl) {
    openShareUrl(shareUrl);
  } else {
    console.error(`No share URL generator defined for site: ${site}`);
  }
});
