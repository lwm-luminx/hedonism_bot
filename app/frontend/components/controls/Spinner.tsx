import React from "react";

export function Spinner() {
  return (
    <div className="flex justify-center items-center" role="status">
      <div className="w-10 h-10 border-4 border-gray-200 border-t-blue-500 rounded-full animate-spin"></div>
      <span className="sr-only">Loading...</span>
    </div>
  );
}
