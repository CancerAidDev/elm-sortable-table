import express from "express";

import knex from "knex";

const db = knex({
  client: "sqlite3",
  connection: {
    filename: "./examples/server/elements.db",
  },
});

const app = express();
const port = 3000;

app.get("/elements", (req, res) => {
  const reqData = req.query;
  let pagination = {};
  const perPage = reqData.perPage || 10;
  const page = reqData.currentPage || 1;
  if (page < 1) page = 1;
  const offset = (page - 1) * perPage;
  const orderBy = reqData.orderBy || "atomic_number";
  const orderDir = reqData.orderDir || "asc";
  return Promise.all([
    db.count("* as count").from("elements").first(),
    db
      .select("*")
      .from("elements")
      .orderBy(orderBy, orderDir)
      .offset(offset)
      .limit(perPage),
  ]).then(([total, rows]) => {
    const count = total.count;
    pagination.total = count;
    pagination.perPage = perPage;
    pagination.offset = offset;
    pagination.to = offset + rows.length;
    pagination.lastPage = Math.ceil(count / perPage);
    pagination.currentPage = page;
    pagination.from = offset;
    pagination.data = rows;
    res.json(rows);
  });
});

app.listen(port, () => {
  console.log(`Server app listening on port ${port}`);
});
