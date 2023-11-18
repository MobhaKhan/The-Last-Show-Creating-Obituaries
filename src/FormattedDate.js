const options = {
    year: "numeric",
    month: "long",
    day: "numeric",
    hour: "numeric",
    minute: "numeric",
  };

  const formatDate = (when) => {
    const formatted = new Date(when).toLocaleString("en-US", options);
    if (formatted === "Invalid Date") {
      return "";
    }
    const formattedDate = formatted.substring(0, formatted.indexOf(",") + 6)
    return formattedDate;
  };

  function FormattedDate({ date }) {
    return <span>{formatDate(date)}</span>;
  }

  export default FormattedDate;